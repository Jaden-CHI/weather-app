-- Golf Windy 운영 데이터 보정
-- 대상:
--   CC_121 남여주
--   CC_109 몽베르컨트리클럽
-- 실행 위치: Railway Postgres SQL Console

BEGIN;

UPDATE golf_courses
SET
    address = '경기도 여주시 가여로 532',
    lat = 37.223966,
    lon = 127.626300,
    grid_x = 71,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_121';

UPDATE golf_courses
SET
    address = '경기도 포천시 영북면 산정호수로 359-12',
    lat = 38.084271,
    lon = 127.311752,
    grid_x = 65,
    grid_y = 138,
    updated_at = NOW()
WHERE course_id = 'CC_109';

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
WHERE course_id IN ('CC_121', 'CC_109')
ORDER BY course_id;
