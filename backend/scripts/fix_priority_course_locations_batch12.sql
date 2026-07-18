-- Golf Windy 운영 데이터 보정 (배치 12)
-- 대상: 화성 상록GC 좌표 보정
-- 실행 위치: Railway Postgres SQL Console

BEGIN;

UPDATE golf_courses
SET address = '경기도 화성시 동탄면 풀무골로60번길 80',
    lat = 37.197115,
    lon = 127.133373,
    grid_x = 63,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_048';

COMMIT;

SELECT course_id, name, address, lat, lon, grid_x, grid_y
FROM golf_courses
WHERE course_id = 'CC_048';
