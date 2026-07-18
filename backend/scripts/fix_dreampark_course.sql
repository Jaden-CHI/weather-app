-- Golf Windy 운영 데이터 보정
-- 대상: CC_171 드림파크골프장
-- 실행 위치: Railway Postgres SQL Console

BEGIN;

UPDATE golf_courses
SET
    address = '인천광역시 검단구 자원순환로260번길 46',
    lat = 37.572663,
    lon = 126.643579,
    grid_x = 54,
    grid_y = 127,
    updated_at = NOW()
WHERE course_id = 'CC_171';

COMMIT;

-- 확인용
SELECT
    course_id,
    name,
    address,
    lat,
    lon,
    grid_x,
    grid_y,
    updated_at
FROM golf_courses
WHERE course_id = 'CC_171';
