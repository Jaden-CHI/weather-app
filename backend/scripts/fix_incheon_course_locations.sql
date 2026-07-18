-- Golf Windy 운영 데이터 보정
-- 대상: 인천권 좌표 오류 코스
-- 실행 위치: Railway Postgres SQL Console

BEGIN;

UPDATE golf_courses
SET
    address = '인천광역시 연수구 아카데미로 209',
    lat = 37.380495,
    lon = 126.624395,
    grid_x = 54,
    grid_y = 123,
    updated_at = NOW()
WHERE course_id = 'CC_413';

UPDATE golf_courses
SET
    address = '인천광역시 검단구 자원순환로260번길 46',
    lat = 37.572663,
    lon = 126.643579,
    grid_x = 54,
    grid_y = 127,
    updated_at = NOW()
WHERE course_id = 'CC_171';

UPDATE golf_courses
SET
    address = '인천광역시 영종구 영종해안남로321번길 184',
    lat = 37.434465,
    lon = 126.455115,
    grid_x = 51,
    grid_y = 124,
    updated_at = NOW()
WHERE course_id = 'CC_174';

COMMIT;

SELECT
    course_id,
    name,
    address,
    lat,
    lon,
    updated_at
FROM golf_courses
WHERE course_id IN ('CC_413', 'CC_171', 'CC_174')
ORDER BY course_id;
