# Golf Course Data QA Checklist

골프장 DB를 현행화하거나 특정 코스의 날씨/지도/식당 추천이 이상할 때 확인하는 운영 체크리스트입니다.

## 1. 기본 데이터 확인

- `backend/data/golf_courses.json` 에 `course_id`, `name`, `name_short`, `address`, `lat`, `lon`, `holes`, `website` 가 들어있는지 확인합니다.
- 주소는 가능하면 도로명 주소를 사용합니다.
- `grid_x`, `grid_y` 는 앱 시작 시 `lat`, `lon` 으로 다시 계산되므로, 실제 기준은 위경도입니다.

## 2. 좌표 검증

```bash
cd /Users/moonyth/Projects/weather-app/backend
python -m scripts.audit_course_locations --query 드림파크
python -m scripts.audit_course_locations --query 영종오렌지
python -m scripts.audit_course_locations --query 남한강에스파크
```

- `distance_km` 가 큰 항목은 카카오/네이버 지도에서 실제 클럽하우스 위치와 비교합니다.
- 같은 지역명만 맞고 실제 위치가 먼 경우, 식당 추천도 같이 틀어질 가능성이 큽니다.

## 3. 운영 DB 반영

- JSON 수정 후 백엔드가 재배포되면 앱 시작 시 `seed_data()` 가 `golf_courses` 테이블을 갱신합니다.
- Railway 콘솔에서 직접 SQL을 반영해야 하는 경우 `backend/scripts/*.sql` 파일을 사용합니다.
- 반영 후 `/api/v1/golf/courses/search?q=골프장명` 으로 검색 결과를 확인합니다.

## 4. 날씨 캐시 확인

```text
GET /api/v1/golf/courses/{course_id}/weather/status
```

- `cached: true` 이면 앱에서 날씨가 표시될 준비가 된 상태입니다.
- `cached: false` 이면 DB에는 있지만 worker가 해당 격자 예보를 아직 수집하지 못한 상태입니다.
- 이 경우 worker 배포 상태와 `REDIS_URL`, `USE_MOCK_DATA`, 날씨 API 키를 확인합니다.

## 5. 앱 QA 순서

1. 설정 > 출시 전 QA 체크에서 일정/지도/날씨/식당/OCR 상태를 확인합니다.
2. 일정 상세에서 공유 버튼을 눌러 카카오톡 또는 문자 공유 시트가 뜨는지 확인합니다.
3. 지도에서 코스 마커와 식당 마커가 실제 코스 주변인지 확인합니다.
4. 스코어 관리에서 OCR 등록 후 골프장명 수정 버튼이 보이는지 확인합니다.
5. 날씨가 없는 코스는 "날씨 준비 중" 안내가 보이는지 확인합니다.
