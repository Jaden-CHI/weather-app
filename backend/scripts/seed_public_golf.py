"""
문화체육관광부 체육시설업 공공데이터 기반 골프장 시드 스크립트

API: https://www.data.go.kr/data/15000440/openapi.do
     (체육시설업 현황 - 골프장업)

실행:
    # API 키 없이 (현재 golf_courses.json 유지)
    python -m scripts.seed_public_golf

    # 실제 공공데이터 수집 (data.go.kr 발급 키)
    PUBLIC_DATA_API_KEY=발급받은키 python -m scripts.seed_public_golf

출력: backend/data/golf_courses.json  (기존 파일 교체)
      ※ 기존 golfzon_linked=True 항목은 자동 보존됩니다.
"""

import asyncio
import json
import math
import os
import re
import sys

import httpx

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))


# ── 기상청 LCC 격자 변환 ─────────────────────────────────────────
def wgs84_to_grid(lat: float, lon: float) -> tuple[int, int]:
    RE, GRID = 6371.00877, 5.0
    SLAT1, SLAT2, OLON, OLAT = 30.0, 60.0, 126.0, 38.0
    XO, YO = 43, 136
    DEGRAD = math.pi / 180.0
    re = RE / GRID
    slat1, slat2 = SLAT1 * DEGRAD, SLAT2 * DEGRAD
    olon_r, olat_r = OLON * DEGRAD, OLAT * DEGRAD
    sn = math.log(math.cos(slat1) / math.cos(slat2)) / math.log(
        math.tan(math.pi * 0.25 + slat2 * 0.5) / math.tan(math.pi * 0.25 + slat1 * 0.5)
    )
    sf = (math.tan(math.pi * 0.25 + slat1 * 0.5) ** sn) * math.cos(slat1) / sn
    ro = re * sf / (math.tan(math.pi * 0.25 + olat_r * 0.5) ** sn)
    ra = re * sf / (math.tan(math.pi * 0.25 + lat * DEGRAD * 0.5) ** sn)
    theta = lon * DEGRAD - olon_r
    theta = max(min(theta, math.pi), -math.pi) * sn
    return int(ra * math.sin(theta) + XO + 0.5), int(ro - ra * math.cos(theta) + YO + 0.5)


# ── 주소 → 시도 추출 ─────────────────────────────────────────────
_REGION_MAP = {
    "서울": "서울", "부산": "부산", "대구": "대구", "인천": "인천",
    "광주": "광주", "대전": "대전", "울산": "울산", "세종": "세종",
    "경기": "경기", "강원": "강원", "충북": "충북", "충남": "충남",
    "전북": "전북", "전남": "전남", "경북": "경북", "경남": "경남",
    "제주": "제주",
}

def extract_region(address: str) -> str:
    for prefix, region in _REGION_MAP.items():
        if address.startswith(prefix):
            return region
    return address.split()[0] if address else "미상"


# ── course_id 생성 ────────────────────────────────────────────────
def make_course_id(idx: int, public_data_id: str) -> str:
    """공공데이터 고유번호 기반 ID 생성 (없으면 순번)"""
    if public_data_id:
        clean = re.sub(r"[^A-Z0-9]", "", public_data_id.upper())[:10]
        return f"PD_{clean}" if clean else f"CC_{idx:04d}"
    return f"CC_{idx:04d}"


# ── 이름 축약형 생성 ─────────────────────────────────────────────
def make_short_name(name: str) -> str:
    name = name.replace("컨트리클럽", "CC").replace("골프클럽", "GC")
    name = name.replace("골프장", "GC").replace("리조트", "리조트")
    return name[:20]


# ── 공공데이터 API 호출 (odcloud) ────────────────────────────────
async def fetch_public_golf_data(api_key: str, per_page: int = 1000) -> list[dict]:
    """
    문화체육관광부_전국 골프장 현황
    Base URL: api.odcloud.kr/api
    Endpoint: /15118920/v1/uddi:0e5b12d2-1cc8-4caf-ba96-c2c7d1ef8d83
    응답 형식: { currentCount, data: [...], totalCount, page, perPage }
    """
    url = "https://api.odcloud.kr/api/15118920/v1/uddi:0e5b12d2-1cc8-4caf-ba96-c2c7d1ef8d83"
    all_items: list[dict] = []
    page = 1

    async with httpx.AsyncClient(timeout=30.0) as client:
        while True:
            params = {
                "serviceKey": api_key,
                "page": page,
                "perPage": per_page,
            }
            try:
                resp = await client.get(url, params=params)
                resp.raise_for_status()
                body = resp.json()

                # 인증 실패 체크
                if body.get("code") and body["code"] != 200:
                    print(f"  [ERROR] API 오류: {body.get('msg', '')}")
                    break

                items = body.get("data", [])
                if not items:
                    break

                all_items.extend(items)
                total = int(body.get("totalCount", 0))
                print(f"  페이지 {page}: {len(items)}개 수집 (누적 {len(all_items)}/{total}개)")

                if len(all_items) >= total:
                    break
                page += 1

            except Exception as e:
                print(f"  [ERROR] 페이지 {page} 수집 실패: {e}")
                break

    return all_items


# ── 공공데이터 항목 → 내부 스키마 변환 ───────────────────────────
def transform_item(idx: int, item: dict) -> dict | None:
    """
    문화체육관광부_전국 골프장 현황 필드 (odcloud 기준):
      사업장명, 소재지도로명주소, 위도, 경도, 홀수, 전화번호
    필드명이 다를 경우를 대비해 복수 키로 시도
    """
    name = (
        item.get("사업장명") or item.get("골프장명") or item.get("시설명") or
        item.get("bplcNm") or item.get("fcltNm") or ""
    ).strip()
    if not name:
        return None

    # 좌표
    try:
        lat = float(
            item.get("위도") or item.get("lat") or item.get("latitude") or
            item.get("y") or 0
        )
        lon = float(
            item.get("경도") or item.get("lon") or item.get("longitude") or
            item.get("x") or 0
        )
    except (TypeError, ValueError):
        lat, lon = 0.0, 0.0

    # 한반도 범위 벗어나면 제외
    if not (33.0 <= lat <= 39.0 and 124.0 <= lon <= 132.0):
        return None

    address = (
        item.get("소재지도로명주소") or item.get("도로명주소") or
        item.get("소재지지번주소") or item.get("rdnWhlAddr") or
        item.get("lnmadr") or ""
    ).strip()
    region = extract_region(address)

    try:
        holes = int(item.get("홀수") or item.get("holeNum") or item.get("holeCnt") or 18)
    except (TypeError, ValueError):
        holes = 18

    public_id = str(item.get("관리번호") or item.get("mgtNo") or item.get("svcId") or "")
    grid_x, grid_y = wgs84_to_grid(lat, lon)

    return {
        "course_id": make_course_id(idx, public_id),
        "name": name,
        "name_short": make_short_name(name),
        "region": region,
        "address": address,
        "lat": round(lat, 6),
        "lon": round(lon, 6),
        "grid_x": grid_x,
        "grid_y": grid_y,
        "holes": holes,
        "phone": (item.get("전화번호") or item.get("telNo") or "").strip() or None,
        "website": None,
        "public_data_id": public_id or None,
        "golfzon_id": None,
        "golfzon_url": None,
        "golfzon_linked": False,
        "data_source": "PUBLIC_DATA",
    }


# ── 시/군 좌표 테이블 (KMA 격자 근사용) ─────────────────────────
_CITY_COORDS: dict[str, tuple[float, float]] = {
    # 서울
    "서울": (37.5665, 126.9780),
    # 경기
    "고양시": (37.6584, 126.8320), "수원시": (37.2636, 127.0286),
    "용인시": (37.2411, 127.1776), "성남시": (37.4449, 127.1389),
    "부천시": (37.5034, 126.7660), "안양시": (37.3943, 126.9568),
    "안산시": (37.3219, 126.8309), "광명시": (37.4784, 126.8647),
    "평택시": (36.9921, 127.1128), "시흥시": (37.3799, 126.8031),
    "의정부시": (37.7382, 127.0338), "파주시": (37.7600, 126.7800),
    "광주시": (37.4296, 127.2556), "이천시": (37.2722, 127.4352),
    "화성시": (37.1996, 126.8312), "여주시": (37.2981, 127.6378),
    "양주시": (37.7855, 127.0457), "가평군": (37.8314, 127.5112),
    "양평군": (37.4916, 127.4875), "연천군": (38.0963, 127.0750),
    "포천시": (37.8945, 127.2003), "동두천시": (37.9035, 127.0605),
    "의왕시": (37.3449, 126.9685), "군포시": (37.3617, 126.9352),
    "과천시": (37.4292, 126.9877), "오산시": (37.1496, 127.0773),
    "안성시": (37.0080, 127.2797), "하남시": (37.5390, 127.2149),
    "구리시": (37.5943, 127.1296), "남양주시": (37.6359, 127.2165),
    "김포시": (37.6152, 126.7155),
    # 강원
    "강릉시": (37.7519, 128.8761), "원주시": (37.3422, 127.9201),
    "춘천시": (37.8813, 127.7298), "속초시": (38.2070, 128.5918),
    "동해시": (37.5244, 129.1142), "태백시": (37.1640, 128.9855),
    "삼척시": (37.4497, 129.1658), "정선군": (37.3800, 128.6608),
    "평창군": (37.3703, 128.3904), "영월군": (37.1834, 128.4614),
    "양구군": (38.1054, 127.9898), "인제군": (38.0695, 128.1706),
    "고성군": (38.3790, 128.4679), "양양군": (38.0760, 128.6192),
    "홍천군": (37.6970, 127.8885), "횡성군": (37.4913, 127.9842),
    "화천군": (38.1060, 127.7084), "철원군": (38.1468, 127.3139),
    # 경북
    "포항시": (36.0190, 129.3435), "경주시": (35.8562, 129.2247),
    "김천시": (36.1397, 128.1136), "안동시": (36.5684, 128.7294),
    "구미시": (36.1195, 128.3446), "영주시": (36.8057, 128.6240),
    "영천시": (35.9733, 128.9382), "상주시": (36.4110, 128.1591),
    "문경시": (36.5862, 128.1862), "경산시": (35.8250, 128.7416),
    "칠곡군": (35.9952, 128.4013), "예천군": (36.6573, 128.4514),
    "봉화군": (36.8935, 128.7320), "울진군": (36.9929, 129.4002),
    "청도군": (35.6474, 128.7361), "고령군": (35.7274, 128.2641),
    "성주군": (35.9197, 128.2827), "군위군": (36.2395, 128.5729),
    "의성군": (36.3527, 128.6969), "청송군": (36.4360, 129.0569),
    "영양군": (36.6664, 129.1126), "영덕군": (36.4152, 129.3651),
    "울릉군": (37.4845, 130.9057),
    # 경남
    "창원시": (35.2280, 128.6811), "진주시": (35.1800, 128.1076),
    "통영시": (34.8544, 128.4333), "사천시": (35.0034, 128.0645),
    "김해시": (35.2285, 128.8892), "밀양시": (35.5036, 128.7460),
    "거제시": (34.8800, 128.6211), "양산시": (35.3350, 129.0367),
    "의령군": (35.3224, 128.2619), "함안군": (35.2730, 128.4079),
    "창녕군": (35.5444, 128.4921), "고성군경남": (34.9730, 128.3228),
    "남해군": (34.8374, 127.8922), "하동군": (35.0675, 127.7516),
    "산청군": (35.4149, 127.8738), "함양군": (35.5208, 127.7253),
    "거창군": (35.6865, 127.9099), "합천군": (35.5667, 128.1655),
    # 전남
    "목포시": (34.8118, 126.3922), "여수시": (34.7604, 127.6622),
    "순천시": (34.9506, 127.4872), "나주시": (35.0160, 126.7108),
    "광양시": (34.9409, 127.6956), "담양군": (35.3214, 126.9882),
    "곡성군": (35.2820, 127.2919), "구례군": (35.2028, 127.4625),
    "고흥군": (34.6043, 127.2754), "보성군": (34.7715, 127.0797),
    "화순군": (34.9647, 126.9864), "장흥군": (34.6818, 126.9075),
    "강진군": (34.6421, 126.7671), "해남군": (34.5736, 126.5993),
    "영암군": (34.8003, 126.6966), "무안군": (34.9901, 126.4819),
    "함평군": (35.0651, 126.5182), "영광군": (35.2771, 126.5120),
    "장성군": (35.3020, 126.7846), "완도군": (34.3108, 126.7549),
    "진도군": (34.4871, 126.2637), "신안군": (34.8298, 126.1069),
    # 전북
    "전주시": (35.8242, 127.1479), "군산시": (35.9679, 126.7368),
    "익산시": (35.9483, 126.9577), "정읍시": (35.5698, 126.8561),
    "남원시": (35.4164, 127.3901), "김제시": (35.8033, 126.8809),
    "완주군": (35.9073, 127.1614), "진안군": (35.7910, 127.4249),
    "무주군": (36.0067, 127.6609), "장수군": (35.6476, 127.5209),
    "임실군": (35.6177, 127.2893), "순창군": (35.3745, 127.1380),
    "고창군": (35.4356, 126.7020), "부안군": (35.7319, 126.7335),
    # 충북
    "청주시": (36.6424, 127.4890), "충주시": (36.9910, 127.9259),
    "제천시": (37.1326, 128.1909), "보은군": (36.4896, 127.7291),
    "옥천군": (36.3063, 127.5705), "영동군": (36.1750, 127.7792),
    "증평군": (36.7854, 127.5815), "진천군": (36.8558, 127.4358),
    "괴산군": (36.8155, 127.7876), "음성군": (36.9400, 127.6900),
    "단양군": (36.9847, 128.3656),
    # 충남
    "천안시": (36.8151, 127.1139), "공주시": (36.4465, 127.1192),
    "보령시": (36.3332, 126.6127), "아산시": (36.7898, 127.0020),
    "서산시": (36.7847, 126.4502), "논산시": (36.1870, 127.0987),
    "계룡시": (36.2741, 127.2491), "당진시": (36.8895, 126.6455),
    "금산군": (36.1086, 127.4882), "부여군": (36.2757, 126.9097),
    "서천군": (36.0790, 126.6929), "청양군": (36.4591, 126.8024),
    "홍성군": (36.6012, 126.6606), "예산군": (36.6800, 126.8451),
    "태안군": (36.7450, 126.2978),
    # 제주
    "제주시": (33.4996, 126.5312), "서귀포시": (33.2541, 126.5600),
    # 광역시
    "인천": (37.4563, 126.7052), "부산": (35.1796, 129.0756),
    "대구": (35.8714, 128.6014), "울산": (35.5384, 129.3114),
    "광주": (35.1595, 126.8526), "대전": (36.3504, 127.3845),
    "세종": (36.4801, 127.2890),
}

def address_to_coords(region: str, address: str) -> tuple[float, float] | None:
    """주소의 시/군 토큰으로 좌표 조회, 없으면 권역 좌표로 폴백."""
    province_tokens = {
        "서울특별시", "부산광역시", "대구광역시", "인천광역시", "광주광역시",
        "대전광역시", "울산광역시", "세종특별자치시", "경기도", "강원도",
        "강원특별자치도", "충청북도", "충청남도", "전라북도", "전북특별자치도",
        "전라남도", "경상북도", "경상남도", "제주특별자치도", "제주도", "제주",
    }
    tokens = address.split() if address else []
    while tokens and tokens[0] in province_tokens:
        tokens.pop(0)

    city = tokens[0] if tokens else ""
    if region == "경남" and city == "고성군":
        city = "고성군경남"
    if city == "연무읍":
        city = "논산시"

    if city in _CITY_COORDS:
        return _CITY_COORDS[city]
    # 광역시/도 레벨 폴백
    if region in _CITY_COORDS:
        return _CITY_COORDS[region]
    return None


# ── CSV 파일 읽기 ─────────────────────────────────────────────────
def load_csv(file_path: str) -> list[dict]:
    import csv as _csv
    for enc in ("utf-8-sig", "cp949", "euc-kr"):
        try:
            with open(file_path, encoding=enc) as f:
                rows = list(_csv.DictReader(f))
            print(f"  CSV 인코딩: {enc}, {len(rows)}행")
            return rows
        except (UnicodeDecodeError, Exception):
            continue
    return []


# ── CSV 항목 → 내부 스키마 변환 ──────────────────────────────────
def transform_csv_item(idx: int, item: dict, golfzon_names: set) -> dict | None:
    name = (item.get("업소명") or "").strip()
    if not name or name in golfzon_names:
        return None

    region_short = item.get("지역", "").strip()
    address_partial = (item.get("소재지") or "").strip()
    # 전체 주소 = 시도 + 부분 주소
    region_full_map = {
        "서울": "서울특별시", "경기": "경기도", "강원": "강원도",
        "경북": "경상북도", "경남": "경상남도", "전남": "전라남도",
        "전북": "전라북도", "충북": "충청북도", "충남": "충청남도",
        "제주": "제주특별자치도", "인천": "인천광역시", "부산": "부산광역시",
        "대구": "대구광역시", "울산": "울산광역시", "광주": "광주광역시",
        "대전": "대전광역시", "세종": "세종특별자치시",
    }
    region = region_full_map.get(region_short, region_short)
    full_prefixes = set(region_full_map.values())
    prefix_aliases = {**region_full_map, "제주도": "제주특별자치도"}
    first_token = address_partial.split()[0] if address_partial else ""
    if first_token in prefix_aliases:
        rest = " ".join(address_partial.split()[1:])
        address = f"{prefix_aliases[first_token]} {rest}".strip()
    elif any(address_partial.startswith(prefix) for prefix in full_prefixes):
        address = address_partial
    else:
        address = f"{region} {address_partial}".strip()

    coords = address_to_coords(region_short, address_partial)
    if not coords:
        return None
    lat, lon = coords

    try:
        holes = int((item.get("홀수(홀)") or "18").strip())
    except (ValueError, AttributeError):
        holes = 18

    course_type = (item.get("세부종류") or "").strip()
    website = (item.get("URL") or "").strip() or None
    grid_x, grid_y = wgs84_to_grid(lat, lon)

    return {
        "course_id": f"CC_{idx:03d}",
        "name": name,
        "name_short": make_short_name(name),
        "region": region_short,
        "address": address,
        "lat": round(lat, 6),
        "lon": round(lon, 6),
        "grid_x": grid_x,
        "grid_y": grid_y,
        "holes": holes,
        "phone": None,
        "website": website,
        "public_data_id": None,
        "golfzon_id": None,
        "golfzon_url": None,
        "golfzon_linked": False,
        "data_source": "PUBLIC_DATA",
        "course_type": course_type,
    }


# ── Mock 데이터 (API 키 없을 때) ─────────────────────────────────
MOCK_COURSES = [
    ("골프존카운티 남촌", "서울특별시 강남구", 37.4730, 127.0395, 18),
    ("골프존카운티 안성", "경기도 안성시 보개면", 37.0121, 127.2784, 27),
    ("골프존카운티 여주", "경기도 여주시 능서면", 37.3012, 127.6341, 18),
    ("골프존카운티 파주", "경기도 파주시 탄현면", 37.7628, 126.7518, 18),
    ("골프존카운티 화성", "경기도 화성시 향남읍", 37.1215, 126.9182, 27),
    ("골프존카운티 춘천", "강원도 춘천시 동면", 37.8712, 127.7853, 18),
    ("골프존카운티 대구", "대구광역시 달성군 현풍읍", 35.7352, 128.4281, 18),
    ("골프존카운티 부산", "부산광역시 기장군 장안읍", 35.2741, 129.2283, 18),
    ("골프존카운티 제주", "제주특별자치도 서귀포시 안덕면", 33.3421, 126.4253, 18),
    ("용인 컨트리클럽", "경기도 용인시 처인구 포곡읍", 37.193, 127.265, 27),
    ("남서울 컨트리클럽", "경기도 성남시 수정구 금토동", 37.396, 127.118, 18),
    ("오크밸리 컨트리클럽", "강원도 원주시 지정면", 37.421, 127.887, 36),
    ("하이원 리조트 골프클럽", "강원도 정선군 고한읍", 37.215, 128.883, 18),
    ("나인브릿지 골프클럽", "제주특별자치도 서귀포시 안덕면", 33.337, 126.417, 18),
    ("핀크스 골프클럽", "제주특별자치도 서귀포시 안덕면", 33.313, 126.430, 18),
    ("블루원 상주 컨트리클럽", "경상북도 상주시 화서면", 36.361, 128.015, 36),
    ("이스트밸리 컨트리클럽", "경기도 이천시 마장면", 37.278, 127.395, 18),
    ("웰링턴 컨트리클럽", "경기도 가평군 설악면", 37.651, 127.554, 18),
    ("엘리시안 강촌 GC", "강원도 춘천시 남산면", 37.702, 127.726, 18),
    ("알펜시아 GC", "강원도 평창군 대관령면", 37.700, 128.693, 18),
]

def make_mock_courses() -> list[dict]:
    results = []
    for idx, (name, address, lat, lon, holes) in enumerate(MOCK_COURSES, 1):
        grid_x, grid_y = wgs84_to_grid(lat, lon)
        region = extract_region(address)
        results.append({
            "course_id": f"CC_{idx:04d}",
            "name": name,
            "name_short": make_short_name(name),
            "region": region,
            "address": address,
            "lat": lat, "lon": lon,
            "grid_x": grid_x, "grid_y": grid_y,
            "holes": holes,
            "phone": None, "website": None,
            "public_data_id": None,
            "golfzon_id": f"GZ_{idx:04d}" if "골프존카운티" in name else None,
            "golfzon_url": f"https://www.golfzon.com/booking/{idx}" if "골프존카운티" in name else None,
            "golfzon_linked": "골프존카운티" in name,
            "data_source": "MOCK",
        })
    return results


# ── 기존 파일에서 골프존 제휴 항목 보존 ─────────────────────────
def load_golfzon_entries(path: str) -> list[dict]:
    """golf_courses.json에서 golfzon_linked=True 항목만 추출"""
    if not os.path.exists(path):
        return []
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    courses = data if isinstance(data, list) else data.get("courses", [])
    return [c for c in courses if c.get("golfzon_linked")]


def load_existing_courses(path: str) -> list[dict]:
    if not os.path.exists(path):
        return []
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    return data if isinstance(data, list) else data.get("courses", [])


# ── 이름 기반 중복 제거 ──────────────────────────────────────────
def dedup_by_name(courses: list[dict]) -> list[dict]:
    seen: dict[str, dict] = {}
    for c in courses:
        key = c["name"].strip()
        if key not in seen:
            seen[key] = c
    return list(seen.values())


# ── course_id 재부여 ──────────────────────────────────────────────
def reassign_ids(
    golfzon: list[dict],
    public: list[dict],
    existing: list[dict] | None = None,
) -> list[dict]:
    """
    기존 이름은 기존 course_id를 유지하고, 신규 코스만 다음 번호를 부여한다.
    저장된 일정이 course_id를 들고 있으므로 재정렬로 ID가 밀리지 않게 한다.
    """
    existing = existing or []
    existing_ids_by_name = {
        c.get("name", "").strip(): c.get("course_id")
        for c in existing
        if c.get("name") and c.get("course_id")
    }
    used_ids = {c.get("course_id") for c in existing if c.get("course_id")}
    next_num = 1
    for course_id in used_ids:
        match = re.fullmatch(r"CC_(\d+)", str(course_id))
        if match:
            next_num = max(next_num, int(match.group(1)) + 1)

    def assign_id(course: dict) -> dict:
        nonlocal next_num
        c = dict(course)
        preserved = existing_ids_by_name.get(c["name"].strip())
        if preserved:
            c["course_id"] = preserved
            used_ids.add(preserved)
            return c
        while f"CC_{next_num:03d}" in used_ids:
            next_num += 1
        c["course_id"] = f"CC_{next_num:03d}"
        used_ids.add(c["course_id"])
        next_num += 1
        return c

    result = []
    for c in golfzon:
        result.append(assign_id(c))
    for c in public:
        result.append(assign_id(c))
    return result


# ── 메인 실행 ─────────────────────────────────────────────────────
async def main():
    import sys
    api_key = os.getenv("PUBLIC_DATA_API_KEY", "")
    data_dir = os.path.join(os.path.dirname(__file__), "..", "data")
    out_path = os.path.join(data_dir, "golf_courses.json")

    # --file 옵션: CSV 직접 읽기
    csv_path = None
    if "--file" in sys.argv:
        idx = sys.argv.index("--file")
        if idx + 1 < len(sys.argv):
            csv_path = sys.argv[idx + 1]
        else:
            # 기본 파일명 자동 탐색
            for fname in os.listdir(data_dir):
                if fname.endswith(".csv") and "골프장" in fname:
                    csv_path = os.path.join(data_dir, fname)
                    break
    else:
        # --file 없어도 data 폴더에 CSV 있으면 자동 사용
        for fname in os.listdir(data_dir):
            if fname.endswith(".csv") and "골프장" in fname:
                csv_path = os.path.join(data_dir, fname)
                break

    # 기존 항목은 course_id 안정성을 위해 보존/참조한다.
    existing_courses = load_existing_courses(out_path)
    golfzon_entries = [c for c in existing_courses if c.get("golfzon_linked")]
    golfzon_names = {c["name"] for c in golfzon_entries}
    print(f"기존 골프존 제휴 항목 보존: {len(golfzon_entries)}개")

    public_courses = []

    if csv_path and os.path.exists(csv_path):
        print(f"\n[CSV 파일] {os.path.basename(csv_path)} 읽는 중...")
        raw_rows = load_csv(csv_path)
        skipped_no_coords = 0
        for idx, row in enumerate(raw_rows, 1):
            transformed = transform_csv_item(idx, row, golfzon_names)
            if transformed:
                public_courses.append(transformed)
            else:
                skipped_no_coords += 1
        public_courses = dedup_by_name(public_courses)
        print(f"  변환 완료: {len(public_courses)}개 (좌표 매핑 불가 {skipped_no_coords}개 제외)")

    elif api_key:
        print(f"\n[공공데이터 API] 골프장 목록 수집 시작...")
        raw_items = await fetch_public_golf_data(api_key)
        for idx, item in enumerate(raw_items, 1):
            transformed = transform_item(idx, item)
            if transformed and transformed["name"] not in golfzon_names:
                public_courses.append(transformed)
        public_courses = dedup_by_name(public_courses)
        print(f"  유효 데이터: {len(public_courses)}개")

    else:
        print("\n[안내] CSV 파일 또는 API 키가 필요합니다.")
        print("  → CSV: data 폴더에 '문화체육관광부_전국 골프장 현황_*.csv' 저장 후 재실행")
        print("  → API: PUBLIC_DATA_API_KEY=발급키 python -m scripts.seed_public_golf")
        print("\n현재 golf_courses.json 을 유지합니다.")
        return

    # course_id 재부여 후 병합 (골프존 먼저)
    merged = reassign_ids(golfzon_entries, public_courses, existing_courses)

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(merged, f, ensure_ascii=False, indent=2)

    print(f"\n✅ 저장 완료: golf_courses.json")
    print(f"   총 {len(merged)}개 골프장")
    print(f"   - 골프존 제휴: {len(golfzon_entries)}개 (CC_001~CC_{len(golfzon_entries):03d})")
    print(f"   - 공공데이터:  {len(public_courses)}개")

    from collections import Counter
    region_counts = Counter(c["region"] for c in merged)
    print("\n지역별 분포 (상위 10개):")
    for region, count in sorted(region_counts.items(), key=lambda x: -x[1])[:10]:
        print(f"  {region}: {count}개")


if __name__ == "__main__":
    asyncio.run(main())
