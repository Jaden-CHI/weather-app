"""
골프장 좌표 이상치 점검 스크립트.

backend/data/golf_courses.json 의 골프장 좌표를
카카오 장소검색 결과와 비교해 큰 오차가 나는 항목을 찾아낸다.

예시:
    python -m scripts.audit_course_locations --query 드림파크
    python -m scripts.audit_course_locations --limit 30 --threshold-km 5
"""

from __future__ import annotations

import argparse
import asyncio
import json
import math
import os
import re
from pathlib import Path

import httpx


ROOT = Path(__file__).resolve().parents[1]
COURSES_PATH = ROOT / "data" / "golf_courses.json"
API_KEYS_DART = ROOT.parent / "flutter_app" / "lib" / "config" / "api_keys.dart"


def _normalize_name(value: str) -> str:
    return re.sub(r"[.\-_/·()\s]", "", value).strip().upper()


def _normalize_text(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip()


_BAD_PLACE_KEYWORDS = (
    "주차장",
    "아파트",
    "은행",
    "365",
    "마트",
    "편의점",
    "관리사무소",
    "클럽하우스",
    "락커",
    "스타트하우스",
)

_AMBIGUOUS_COURSE_RULES = {
    _normalize_name("골프존카운티 안성"): {
        "reason": "안성H / 안성W 개별 코스와 대표명이 혼재되어 자동 보정에 부적합",
        "queries": ["골프존카운티 안성", "골프존카운티 안성H", "골프존카운티 안성W"],
    },
    _normalize_name("골프존카운티 제주"): {
        "reason": "골프존카운티오라 등과 브랜드명이 겹쳐 자동 보정에 부적합",
        "queries": ["골프존카운티 제주", "골프존카운티오라"],
    },
}

_COURSE_NAME_ALIASES = {
    _normalize_name("고양컨트리클럽"): {
        _normalize_name("고양CC"),
    },
    _normalize_name("한양컨트리클럽"): {
        _normalize_name("서울한양CC"),
    },
    _normalize_name("한양컨트리클럽 대중제 9홀 골프장"): {
        _normalize_name("한양파인CC"),
    },
    _normalize_name("올림픽 골프장"): {
        _normalize_name("올림픽CC"),
    },
}

_QUERY_OVERRIDE_RULES = {
    _normalize_name("고양컨트리클럽"): [
        "고양CC",
        "고양 컨트리클럽",
        "고양CC 흥도로 304-23",
    ],
    _normalize_name("올림픽 골프장"): [
        "올림픽CC",
        "올림픽CC 혜음로 301",
    ],
    _normalize_name("한양컨트리클럽"): [
        "서울한양CC",
        "한양컨트리클럽",
    ],
    _normalize_name("한양컨트리클럽 대중제 9홀 골프장"): [
        "한양파인CC",
        "한양파인",
    ],
    _normalize_name("여주"): [
        "YJC 골프클럽",
        "여주클래식골프클럽",
        "여주cc 월평로 78",
    ],
    _normalize_name("금강"): [
        "금강컨트리클럽 여주",
        "금강CC 여주남로 541",
    ],
    _normalize_name("세라지오GC"): [
        "더 시에나 벨루토 컨트리클럽",
        "세라지오GC",
        "세라지오GC 여양로 530",
    ],
    _normalize_name("1.2.3"): [
        "123 골프클럽",
        "1.2.3 골프클럽",
        "1.2.3 골프클럽 통일로 43-168",
    ],
    _normalize_name("CLUBD 금강"): [
        "CLUBD 금강",
        "CLUBD 금강 강변로 130",
    ],
    _normalize_name("발리오스대중"): [
        "발리오스CC",
        "발리오스CC 9홀",
    ],
    _normalize_name("라비돌대중"): [
        "라비돌CC",
        "라비돌CC 세자로 286",
    ],
    _normalize_name("상록GC"): [
        "화성상록GC",
        "화성상록골프클럽",
        "풀무골로60번길 80",
    ],
}

_SKIP_SCAN_COURSE_IDS = {
    "CC_001",  # 골프존카운티 남촌 legacy mock
    "CC_003",  # 골프존카운티 여주 legacy mock
    "CC_004",  # 골프존카운티 파주 legacy mock
    "CC_005",  # 골프존카운티 화성 legacy mock
    "CC_006",  # 골프존카운티 춘천 legacy mock
    "CC_007",  # 골프존카운티 대구 legacy mock
    "CC_008",  # 골프존카운티 부산 legacy mock
}


def _resolve_kakao_key() -> str:
    env_key = os.getenv("KAKAO_REST_API_KEY", "").strip()
    if env_key:
        return env_key

    if API_KEYS_DART.exists():
        match = re.search(
            r"kakaoMapKey\s*=\s*'([^']+)'",
            API_KEYS_DART.read_text(encoding="utf-8"),
        )
        if match:
            return match.group(1).strip()
    return ""


def _distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    radius = 6371.0
    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)
    a = (
        math.sin(d_lat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(d_lon / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return radius * c


def _looks_like_same_course(place_name: str, course_name: str) -> bool:
    place = _normalize_name(place_name)
    course = _normalize_name(course_name)
    aliases = _COURSE_NAME_ALIASES.get(course, set())
    return place == course or place in course or course in place or place in aliases


def _is_supporting_place(place_name: str) -> bool:
    normalized = _normalize_text(place_name)
    return any(keyword in normalized for keyword in _BAD_PLACE_KEYWORDS)


def _address_tokens(address: str) -> set[str]:
    tokens = []
    for raw in re.split(r"\s+", address.strip()):
        token = raw.strip(",()")
        if len(token) < 2:
            continue
        tokens.append(token)
    return set(tokens[:4])


def _score_candidate(doc: dict, course_name: str, address: str) -> int:
    place_name = doc.get("place_name", "") or ""
    place_address = doc.get("road_address_name") or doc.get("address_name") or ""
    score = 0

    if _looks_like_same_course(place_name, course_name):
        score += 10

    course_tokens = _address_tokens(address)
    place_tokens = _address_tokens(place_address)
    score += len(course_tokens & place_tokens) * 2

    if doc.get("road_address_name"):
        score += 1

    if _is_supporting_place(place_name):
        score -= 4

    return score


async def _search_candidates(
    client: httpx.AsyncClient,
    auth_key: str,
    query: str,
) -> list[dict]:
    resp = await client.get(
        "https://dapi.kakao.com/v2/local/search/keyword.json",
        params={"query": query, "size": 5},
        headers={"Authorization": f"KakaoAK {auth_key}"},
    )
    resp.raise_for_status()
    return resp.json().get("documents", [])


def _format_candidates(documents: list[dict]) -> str:
    lines: list[str] = []
    for doc in documents[:3]:
        place_name = doc.get("place_name", "") or ""
        place_addr = doc.get("road_address_name") or doc.get("address_name") or ""
        lines.append(f"{place_name} @ {place_addr}")
    return " | ".join(lines)


async def _lookup_course_place(
    client: httpx.AsyncClient,
    auth_key: str,
    course_name: str,
    address: str,
) -> tuple[dict | None, str | None]:
    normalized_course_name = _normalize_name(course_name)
    ambiguous_rule = _AMBIGUOUS_COURSE_RULES.get(normalized_course_name)
    query_override = _QUERY_OVERRIDE_RULES.get(normalized_course_name, [])
    queries = [
        course_name.strip(),
        f"{course_name.strip()} {address.strip()}".strip(),
    ]
    if query_override:
        queries = list(dict.fromkeys(query_override + queries))
    if ambiguous_rule:
        queries = list(dict.fromkeys(ambiguous_rule["queries"] + queries))

    all_documents: list[dict] = []
    for query in dict.fromkeys(q for q in queries if q):
        try:
            documents = await _search_candidates(client, auth_key, query)
            if not documents:
                continue
            all_documents.extend(documents)
        except Exception as exc:
            print(f"[WARN] Kakao lookup failed for {course_name}: {exc}")

    if not all_documents:
        return None, None

    deduped: list[dict] = []
    seen = set()
    for doc in all_documents:
        key = (
            doc.get("place_name", ""),
            doc.get("road_address_name") or doc.get("address_name") or "",
            doc.get("x", ""),
            doc.get("y", ""),
        )
        if key in seen:
            continue
        seen.add(key)
        deduped.append(doc)

    if ambiguous_rule:
        reason = ambiguous_rule["reason"]
        return None, f"{reason} | candidates: {_format_candidates(deduped)}"

    ranked = sorted(
        deduped,
        key=lambda doc: _score_candidate(doc, course_name, address),
        reverse=True,
    )
    return ranked[0], None


async def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--query", help="특정 골프장 이름 포함 필터")
    parser.add_argument("--limit", type=int, default=20, help="최대 점검 개수")
    parser.add_argument(
        "--threshold-km",
        type=float,
        default=5.0,
        help="이 거리 이상 차이나면 이상치로 표시",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="threshold 이하여도 모두 출력",
    )
    args = parser.parse_args()

    kakao_key = _resolve_kakao_key()
    if not kakao_key:
        raise SystemExit("KAKAO_REST_API_KEY 가 없고 flutter_app api_keys.dart 에서도 찾지 못했습니다.")

    courses = json.loads(COURSES_PATH.read_text(encoding="utf-8"))
    filtered = courses
    if args.query:
        filtered = [
            item for item in courses if args.query.strip() in (item.get("name") or "")
        ]
    else:
        filtered = [
            item
            for item in filtered
            if item.get("course_id") not in _SKIP_SCAN_COURSE_IDS
        ]
    filtered = filtered[: args.limit]

    if not filtered:
        raise SystemExit("점검할 골프장이 없습니다.")

    found_any = False
    async with httpx.AsyncClient(timeout=15.0) as client:
        for course in filtered:
            name = course.get("name", "")
            address = course.get("address", "") or ""
            lat = float(course.get("lat"))
            lon = float(course.get("lon"))
            found, review_reason = await _lookup_course_place(
                client, kakao_key, name, address
            )
            if review_reason:
                found_any = True
                print("=" * 72)
                print(f"{name} ({course.get('course_id')})")
                print(f"- current : {lat:.6f}, {lon:.6f}")
                print(f"- review  : {review_reason}")
                print(f"- address : {address}")
                continue
            if not found:
                print(f"[MISS] {name}")
                continue

            found_lat = float(found["y"])
            found_lon = float(found["x"])
            drift_km = _distance_km(lat, lon, found_lat, found_lon)
            if not args.all and drift_km < args.threshold_km:
                continue

            found_any = True
            print("=" * 72)
            print(f"{name} ({course.get('course_id')})")
            print(f"- current : {lat:.6f}, {lon:.6f}")
            print(f"- kakao   : {found_lat:.6f}, {found_lon:.6f}")
            print(f"- drift   : {drift_km:.2f} km")
            print(f"- address : {address}")
            print(
                f"- kakao a : {found.get('road_address_name') or found.get('address_name') or ''}"
            )
            print(f"- place   : {found.get('place_name') or ''}")

    if not found_any:
        print(
            f"[OK] threshold {args.threshold_km}km 이상 좌표 이상치는 발견되지 않았습니다."
        )


if __name__ == "__main__":
    asyncio.run(main())
