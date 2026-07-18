-- Golf Windy 운영 데이터 보정 (배치 10)
-- 대상: 화성권 주소 일치 기반 보정 코스
-- 실행 위치: Railway Postgres SQL Console

BEGIN;

UPDATE golf_courses
SET address = '경기도 화성시 동탄면 중리길 183',
    lat = 37.190282,
    lon = 127.112765,
    grid_x = 62,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_043';

UPDATE golf_courses
SET address = '경기도 화성시 동탄면 풀무골로106번길 244',
    lat = 37.191360,
    lon = 127.146529,
    grid_x = 63,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_044';

COMMIT;

SELECT course_id, name, address, lat, lon, grid_x, grid_y
FROM golf_courses
WHERE course_id IN ('CC_043', 'CC_044')
ORDER BY course_id;
