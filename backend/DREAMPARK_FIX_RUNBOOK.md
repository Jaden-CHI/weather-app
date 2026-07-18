# DreamPark Fix Runbook

드림파크골프장(`CC_171`) 좌표/주소 오류를 운영 환경에 반영하는 절차입니다.

## 목적

기존 운영 데이터:

- 주소: `인천광역시 인천시 서구 거월로 61`
- 좌표: `37.4563, 126.7052`

수정 데이터:

- 주소: `인천광역시 검단구 자원순환로260번길 46`
- 좌표: `37.572663, 126.643579`
- 격자: `grid_x=54`, `grid_y=127`

## 1. Railway Postgres에서 즉시 수정

Railway 프로젝트의 Postgres SQL Console에서 아래 파일 내용을 실행합니다.

- [scripts/fix_dreampark_course.sql](/Users/moonyth/Projects/weather-app/backend/scripts/fix_dreampark_course.sql)

실행 후 마지막 `SELECT` 결과가 아래처럼 나오면 정상입니다.

```sql
course_id = CC_171
name      = 드림파크골프장
address   = 인천광역시 검단구 자원순환로260번길 46
lat       = 37.572663
lon       = 126.643579
grid_x    = 54
grid_y    = 127
```

## 2. API 확인

브라우저 또는 `curl` 로 아래를 확인합니다.

```bash
curl 'https://weather-app-production-7ab9.up.railway.app/api/v1/golf/courses/search?q=드림파크골프장'
```

기대값:

- `course_id: CC_171`
- `address: 인천광역시 검단구 자원순환로260번길 46`
- `lat: 37.572663`
- `lon: 126.643579`

## 3. 백엔드 소스 반영

재시드 시 다시 틀어지지 않도록 아래 파일이 이미 수정되어 있습니다.

- [data/golf_courses.json](/Users/moonyth/Projects/weather-app/backend/data/golf_courses.json)
- [scripts/seed_public_golf.py](/Users/moonyth/Projects/weather-app/backend/scripts/seed_public_golf.py)

즉시 장애복구만 필요하면 SQL 반영만 먼저 해도 됩니다.

운영 안정화까지 하려면 이후 백엔드 재배포도 권장합니다.

## 4. 재배포 권장 순서

1. Git 반영
2. Railway `api` 재배포
3. Railway `worker` 재배포
4. `/health` 확인
5. `courses/search?q=드림파크골프장` 재확인

## 5. 앱 확인 포인트

앱에서 드림파크 일정 상세 진입 후 아래를 확인합니다.

1. 맛집 추천 진입
2. 조식/중식 리스트 주소가 `검단구`, `서구` 권역 위주로 나오는지 확인
3. 간석동/구월동/인천시청 주변 식당이 상단에 다시 뜨지 않는지 확인

## 6. 참고

앱 코드에도 방어 로직이 추가되어 있습니다.

- 골프장 좌표가 백엔드와 카카오 장소검색 결과에서 크게 어긋나면 앱이 더 신뢰도 높은 좌표를 우선 사용
- 같은 `구/군/시` 주소를 맛집 정렬에 우선 반영

즉,

- 운영 DB 수정: 즉시 효과
- 백엔드 재배포: 재발 방지
- 앱 업데이트: 추가 안정화

## 7. 좌표 점검 스크립트

특정 골프장 또는 여러 골프장의 좌표 이상치를 다시 확인하려면:

```bash
cd backend
python3 scripts/audit_course_locations.py --query 드림파크 --all
python3 scripts/audit_course_locations.py --limit 30 --threshold-km 5
```

현재 드림파크 정상 예시:

```text
드림파크골프장 (CC_171)
- drift   : 0.00 km
```
