-- Golf Windy 운영 데이터 보정
-- 대상: 인천권 좌표 오류 2차 코스
-- 실행 위치: Railway Postgres SQL Console

BEGIN;

UPDATE golf_courses
SET
    address = '인천광역시 연수구 인천신항대로 1120',
    lat = 37.353972,
    lon = 126.592109,
    grid_x = 53,
    grid_y = 122,
    updated_at = NOW()
WHERE course_id = 'CC_172';

UPDATE golf_courses
SET
    address = '인천광역시 강화군 삼산면 어류정길177번길 15',
    lat = 37.653656,
    lon = 126.344637,
    grid_x = 49,
    grid_y = 129,
    updated_at = NOW()
WHERE course_id = 'CC_173';

UPDATE golf_courses
SET
    address = '인천광역시 강화군 길상면 해안남로 392',
    lat = 37.603586,
    lon = 126.514548,
    grid_x = 52,
    grid_y = 127,
    updated_at = NOW()
WHERE course_id = 'CC_175';

COMMIT;

SELECT
    course_id,
    name,
    address,
    lat,
    lon,
    grid_x,
    grid_y
FROM golf_courses
WHERE course_id IN ('CC_172', 'CC_173', 'CC_175')
ORDER BY course_id;
