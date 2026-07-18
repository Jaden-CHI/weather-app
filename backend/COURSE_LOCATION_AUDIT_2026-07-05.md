# Course Location Audit

Date: 2026-07-05

## Summary

카카오 장소검색과 `backend/data/golf_courses.json` 좌표를 비교한 결과,
드림파크 외에도 공개데이터 기반 일부 골프장 좌표가 실제 위치와 크게 어긋나는 것으로 보입니다.

특히 아래 패턴이 확인되었습니다.

1. `용인권 골프장 다수`가 같은 기준 좌표를 공유
   - current: `37.241100, 127.177600`
   - 이 값은 개별 코스 좌표가 아니라 권역 대표점으로 보임

2. `검색명/브랜드명 충돌` 케이스 존재
   - 예: `1.2.3 (CC_013)` -> 카카오가 아파트명을 잡아버림
   - 예: `골프존카운티 제주` -> `골프존카운티 오라`로 잘못 연결
   - 예: `골프존카운티 안성` -> `안성H / 안성W` 개별 코스와 대표명이 혼재

3. `초기 MOCK 골프존 제휴 코스`가 여전히 검색에 섞일 수 있음
   - `CC_001~CC_009` 는 공공데이터가 아니라 초기 mock seed 항목
   - 이 중 `CC_002`, `CC_009` 는 현재도 상세 조회 호환을 위해 유지하되
     검색에서는 실제 코스(`안성H/W`, `오라`)를 우선 노출하는 편이 적절

4. `이름은 맞지만 좌표만 대략치`인 케이스 다수
   - 예: 용인/안성 권역 코스들

## Confirmed Fixed

- `CC_171 드림파크골프장`
  - before drift: 약 16.16km
  - now drift: `0.00km`

- `CC_019 수원CC`
  - now drift: `0.00km`

- `CC_041 세현CC`
  - now drift: `0.00km`

- `CC_094 골프존카운티 안성H`
  - now drift: `0.00km`

- `CC_103 골프존카운티 안성W`
  - now drift: `0.00km`

- `CC_513 골프존카운티오라`
  - same name / same address 기준으로 보정 반영 완료

- `CC_164 인천국제컨트리클럽`
  - address/name 기준으로 보정 반영 완료

- `CC_166 송도골프클럽`
  - address/name 기준으로 보정 반영 완료

- `CC_167 인천그랜드컨트리클럽`
  - address 기준으로 보정 반영 완료

- `CC_414 클럽72(바다코스)`
  - support place name 이지만 도로명 주소 일치 기준으로 보정 반영 완료

- `CC_415 클럽72(하늘코스)`
  - support place name 이지만 도로명 주소 일치 기준으로 보정 반영 완료

- `CC_416 베어즈베스트 청라`
  - support place name 이지만 도로명 주소 일치 기준으로 보정 반영 완료

- `CC_121 남여주`
  - address/name 기준으로 보정 반영 완료

- `CC_122 소피아그린`
  - address/name 기준으로 보정 반영 완료

- `CC_123 솔모로`
  - address/name 기준으로 보정 반영 완료

- `CC_125 자유`
  - address/name 기준으로 보정 반영 완료

- `CC_127 아리지`
  - address/name 기준으로 보정 반영 완료

- `CC_128 이포`
  - address/name 기준으로 보정 반영 완료

- `CC_129 렉스필드`
  - address/name 기준으로 보정 반영 완료

- `CC_130 블루헤런`
  - address/name 기준으로 보정 반영 완료

- `CC_137 여주썬밸리`
  - address/name 기준으로 보정 반영 완료

- `CC_126 빅토리아`
  - address/name 기준으로 보정 반영 완료

- `CC_132 스카이밸리`
  - address/name 기준으로 보정 반영 완료

- `CC_133 캐슬파인`
  - address/name 기준으로 보정 반영 완료

- `CC_134 해슬리나인브릿지`
  - address/name 기준으로 보정 반영 완료

- `CC_138 페럼`
  - address/name 기준으로 보정 반영 완료

- `CC_120 여주`
  - 공식 사이트 `YJC / Yeo Ju Classic Golf Club` 주소 기준으로 보정 반영 완료

- `CC_124 금강`
  - 공식 사이트상 코스 주소 `금강그린길 84` 기준으로 보정 반영 완료

- `CC_135 세라지오GC`
  - 공식 리브랜딩 명칭 `더 시에나 벨루토 컨트리클럽(구, 세라지오GC)` 기준으로 보정 반영 완료

- `CC_013 1.2.3`
  - 공식 사이트/카카오 `123골프클럽` 기준으로 보정 반영 완료

- `CC_488 CLUBD 금강`
  - 공식 사이트/카카오 `CLUBD금강` 기준으로 보정 반영 완료

- `CC_043 리베라CC`
  - address/name 기준으로 보정 반영 완료

- `CC_044 기흥CC`
  - address/name 기준으로 보정 반영 완료

- `CC_046 발리오스대중`
  - 대표 코스 `발리오스CC` 와 동일 부지 기준으로 보정 반영 완료

- `CC_047 라비돌대중`
  - 대표 코스 `라비돌CC` 와 동일 부지 기준으로 보정 반영 완료

- `CC_048 상록GC`
  - 검색 별칭 `화성상록GC` 기준으로 보정 반영 완료

## Fixed In Source

다음 항목은 소스 기준 좌표/주소 보정 반영 완료:

- `CC_171` 드림파크골프장
- `CC_039` 써닝포인트CC
- `CC_037` 용인CC
- `CC_030` 블루원용인CC
- `CC_033` 지산CC
- `CC_020` 플라자CC
- `CC_018` 양지파인CC
- `CC_035` 한림용인CC
- `CC_034` 화산CC
- `CC_025` 레이크사이드CC
- `CC_017` 한원CC
- `CC_019` 수원CC
- `CC_021` 태광CC
- `CC_022` 한성CC
- `CC_023` 골드CC
- `CC_024` 88CC
- `CC_026` 남부CC
- `CC_027` 신원CC
- `CC_028` 은화삼CC
- `CC_029` 아시아나CC
- `CC_031` 코리아CC
- `CC_032` 코리아퍼브릭
- `CC_036` 글렌로스골프클럽
- `CC_040` 해솔리아CC
- `CC_041` 세현CC
- `CC_094` 골프존카운티 안성H
- `CC_103` 골프존카운티 안성W
- `CC_513` 골프존카운티오라
- `CC_164` 인천국제컨트리클럽
- `CC_166` 송도골프클럽
- `CC_167` 인천그랜드컨트리클럽
- `CC_414` 클럽72(바다코스)
- `CC_415` 클럽72(하늘코스)
- `CC_416` 베어즈베스트 청라
- `CC_121` 남여주
- `CC_122` 소피아그린
- `CC_123` 솔모로
- `CC_125` 자유
- `CC_127` 아리지
- `CC_128` 이포
- `CC_129` 렉스필드
- `CC_130` 블루헤런
- `CC_137` 여주썬밸리
- `CC_126` 빅토리아
- `CC_132` 스카이밸리
- `CC_133` 캐슬파인
- `CC_134` 해슬리나인브릿지
- `CC_138` 페럼
- `CC_120` 여주
- `CC_124` 금강
- `CC_135` 세라지오GC
- `CC_013` 1.2.3
- `CC_488` CLUBD 금강
- `CC_043` 리베라CC
- `CC_044` 기흥CC
- `CC_046` 발리오스대중
- `CC_047` 라비돌대중
- `CC_048` 상록GC
- `CC_010` 한양컨트리클럽
- `CC_012` 고양컨트리클럽
- `CC_014` 올림픽 골프장
- `CC_016` 한양컨트리클럽 대중제 9홀 골프장

운영 DB 즉시 반영용 SQL:

- [scripts/fix_priority_course_locations.sql](/Users/moonyth/Projects/weather-app/backend/scripts/fix_priority_course_locations.sql)
- [scripts/fix_priority_course_locations_batch2.sql](/Users/moonyth/Projects/weather-app/backend/scripts/fix_priority_course_locations_batch2.sql)
- [scripts/fix_priority_course_locations_batch3.sql](/Users/moonyth/Projects/weather-app/backend/scripts/fix_priority_course_locations_batch3.sql)
- [scripts/fix_priority_course_locations_batch4.sql](/Users/moonyth/Projects/weather-app/backend/scripts/fix_priority_course_locations_batch4.sql)
- [scripts/fix_priority_course_locations_batch5.sql](/Users/moonyth/Projects/weather-app/backend/scripts/fix_priority_course_locations_batch5.sql)
- [scripts/fix_priority_course_locations_batch6.sql](/Users/moonyth/Projects/weather-app/backend/scripts/fix_priority_course_locations_batch6.sql)
- [scripts/fix_priority_course_locations_batch7.sql](/Users/moonyth/Projects/weather-app/backend/scripts/fix_priority_course_locations_batch7.sql)
- [scripts/fix_priority_course_locations_batch8.sql](/Users/moonyth/Projects/weather-app/backend/scripts/fix_priority_course_locations_batch8.sql)
- [scripts/fix_priority_course_locations_batch9.sql](/Users/moonyth/Projects/weather-app/backend/scripts/fix_priority_course_locations_batch9.sql)
- [scripts/fix_priority_course_locations_batch10.sql](/Users/moonyth/Projects/weather-app/backend/scripts/fix_priority_course_locations_batch10.sql)
- [scripts/fix_priority_course_locations_batch11.sql](/Users/moonyth/Projects/weather-app/backend/scripts/fix_priority_course_locations_batch11.sql)
- [scripts/fix_priority_course_locations_batch12.sql](/Users/moonyth/Projects/weather-app/backend/scripts/fix_priority_course_locations_batch12.sql)
- [scripts/fix_priority_course_locations_batch13.sql](/Users/moonyth/Projects/weather-app/backend/scripts/fix_priority_course_locations_batch13.sql)

추가로 `CC_010`, `CC_012`, `CC_014`, `CC_016` 은
`backend/data/golf_courses.json` 과 `backend/scripts/seed_public_golf.py`
오버라이드에 반영되어 다음 backend 기동 시 자동 upsert 됩니다.

앱 측 완충 장치도 이미 반영됨:

- `flutter_app/lib/services/weather_api_service.dart`
  - 카카오 장소검색 기준으로 코스 좌표를 재검증
  - 백엔드 좌표와 실좌표 차이가 크면 앱에서 신뢰 좌표를 우선 사용
- `flutter_app/lib/screens/event_detail_screen.dart`
  - 보정된 좌표/주소를 일정 상세와 맛집 추천 화면에 반영

백엔드 검색 완충 장치도 반영됨:

- `backend/models/database.py`
  - `CC_001~CC_009` legacy mock 골프존 대표명 코스는 일반 검색 결과에서 숨김
  - `골프존카운티 제주` 검색 시 `골프존카운티오라` 별칭까지 함께 조회
  - 기존 저장 일정이 과거 course_id 를 들고 있어도 `get_course()` 는 계속 응답 가능
  - `get_course()` / 날씨 응답에 아래 메타데이터를 함께 노출
    - `is_legacy_mock_course`
    - `legacy_course_status`
    - `legacy_course_reason`
    - `legacy_search_hidden`
    - `legacy_replacement_courses`

감사 스크립트 개선도 반영됨:

- `backend/scripts/audit_course_locations.py`
  - `주차장`, `은행`, `아파트` 같은 보조 장소명을 감점 처리
  - `골프존카운티 안성`, `골프존카운티 제주` 는 자동 보정이 아닌 `review` 대상으로 출력
  - 다만 도로명 주소가 코스 주소와 정확히 맞는 경우는 수동 승인 후 보정 후보로 사용할 수 있음
  - `여주`, `금강`, `세라지오GC` 는 검색 별칭을 사용해 더 정확한 코스명으로 조회
  - `1.2.3`, `CLUBD 금강` 도 검색 별칭을 사용해 정확한 공식 명칭으로 조회
  - `발리오스대중`, `라비돌대중` 은 대표 코스명으로 조회해 동일 부지 좌표를 사용
  - `상록GC` 는 `화성상록GC` 별칭으로 조회해 안산 `제일CC` 오탐을 회피
  - `고양컨트리클럽`, `올림픽 골프장`, `한양컨트리클럽`, `한양컨트리클럽 대중제 9홀 골프장` 은 현장 표기(`고양CC`, `올림픽CC`, `서울한양CC`, `한양파인CC`) 별칭을 사용해 오탐을 줄임

## Remaining Representative-name Candidates

다음 항목은 원천 데이터 기준으로는 drift 가 크지만, 현재 API 레벨에서는
프록시 좌표를 적용해 사용자 노출 품질을 우선 보정한 상태입니다.

| course_id | name | raw current | proxy course | proxy coords | raw drift | user-facing status |
|---|---|---|---|---|---:|---|
| CC_009 | 골프존카운티 제주 | 33.342100, 126.425300 | CC_513 골프존카운티오라 | 33.448082, 126.513306 | 14.34km | mitigated |
| CC_002 | 골프존카운티 안성 | 37.012100, 127.278400 | CC_094 골프존카운티 안성H | 37.095410, 127.341550 | 10.83km | mitigated |

현재 코드 동작:

- `backend/models/database.py`
  - `get_course()` / `search_courses()` 응답에서 대표명 코스의 좌표를 프록시 코스로 덮어씀
  - `CC_002 골프존카운티 안성` -> `CC_094 골프존카운티 안성H`
  - `CC_009 골프존카운티 제주` -> `CC_513 골프존카운티오라`

의미:

- 앱 검색 결과에서 `골프존카운티 안성`, `골프존카운티 제주` 가 먼저 잡혀도
  날씨 / 맛집 / 지도 중심점은 대표 좌표가 아니라 실제 운영 코스 좌표를 사용
- 다만 seed 원본 데이터 자체는 아직 대표명/중복 정리 부채가 남아 있으므로
  장기적으로는 source 정규화 또는 관계 모델링이 필요

추가 주의:

- `CC_002 골프존카운티 안성`
  - 카카오 검색은 `골프존카운티 안성H` 로 연결됨
  - 데이터셋에는 이미 `CC_094 골프존카운티 안성H`, `CC_103 골프존카운티 안성W` 가 따로 존재
  - 따라서 현재는 `대표명 검색 대응용 프록시`로 처리하고 있음

- `CC_009 골프존카운티 제주`
  - 카카오 검색은 `골프존카운티 오라` 를 반환
  - 데이터셋에는 이미 `CC_513 골프존카운티오라` 가 존재
  - 따라서 현재는 `대표명 검색 대응용 프록시`로 처리하고 있음

## Likely Data Quality Cause

`backend/scripts/seed_public_golf.py` 에서 공공데이터 CSV 항목 변환 시
정확한 좌표가 없으면 `address_to_coords()` 를 통해 시/군 대표 좌표로 폴백합니다.

그 결과:

- 여러 개별 골프장이 동일한 권역 대표 좌표를 공유
- 날씨 격자 / 맛집 추천 / 지도 중심점 품질이 함께 떨어짐

## Recommended Next Steps

1. `대표명/중복 코스` 정리 규칙 추가
   - `골프존카운티 안성` -> `안성H / 안성W` 와 관계 정리
   - `골프존카운티 제주` -> `골프존카운티오라` 와 관계 정리

2. `다음 권역` 순차 보정
   - 제주권 대표좌표 공유군
   - 인천권 잔여 대표좌표 공유군 (`잭니클라우스 골프클럽 코리아`, `오렌지듄스영종GC`, `영종오렌지골프장` 등)
   - 충주권/안성권/제주권 대규모 대표좌표 공유군

3. 카카오 장소검색 기반 반자동 보정 도입 검토
   - `audit_course_locations.py` 결과를 바탕으로
   - drift 5km 이상 후보를 수동 승인 후 오버라이드 목록에 반영

4. seed 스크립트 강화
   - 브랜드명이 모호한 코스는 카카오 검색 결과를 그대로 신뢰하지 않도록 예외 처리
   - `주차장`, `아파트`, `클럽하우스` 등 place name 제외 규칙 추가 고려

## Commands

```bash
cd backend
python3 scripts/audit_course_locations.py --query 드림파크 --all
python3 scripts/audit_course_locations.py --limit 40 --threshold-km 5
python3 scripts/audit_course_locations.py --limit 40 --threshold-km 10
```
