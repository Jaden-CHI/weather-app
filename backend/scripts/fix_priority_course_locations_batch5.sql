-- Golf Windy 운영 데이터 보정 (배치 5)
-- 대상: 인천권 주소 일치 기반 보정 코스
-- 실행 위치: Railway Postgres SQL Console

BEGIN;

UPDATE golf_courses
SET address = '인천광역시 인천시 서구 원석로 195',
    lat = 37.513663,
    lon = 126.641181,
    grid_x = 54,
    grid_y = 126,
    updated_at = NOW()
WHERE course_id = 'CC_167';

UPDATE golf_courses
SET address = '인천광역시 인천시 중구 공항동로 392',
    lat = 37.484590,
    lon = 126.469293,
    grid_x = 51,
    grid_y = 125,
    updated_at = NOW()
WHERE course_id = 'CC_414';

UPDATE golf_courses
SET address = '인천광역시 인천시 중구 공항동로135번길 267',
    lat = 37.453840,
    lon = 126.483959,
    grid_x = 51,
    grid_y = 124,
    updated_at = NOW()
WHERE course_id = 'CC_415';

UPDATE golf_courses
SET address = '인천광역시 인천시 서구 청라대로 316번길 45',
    lat = 37.548656,
    lon = 126.635928,
    grid_x = 54,
    grid_y = 126,
    updated_at = NOW()
WHERE course_id = 'CC_416';

COMMIT;

SELECT course_id, name, address, lat, lon, grid_x, grid_y
FROM golf_courses
WHERE course_id IN ('CC_167', 'CC_414', 'CC_415', 'CC_416')
ORDER BY course_id;
