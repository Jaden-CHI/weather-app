-- Golf Windy 운영 데이터 보정 (배치 11)
-- 대상: 화성권 퍼블릭 9홀 보정 코스
-- 실행 위치: Railway Postgres SQL Console

BEGIN;

UPDATE golf_courses
SET address = '경기도 화성시 팔탄면 3.1만세로 641-28',
    lat = 37.115608,
    lon = 126.860830,
    grid_x = 58,
    grid_y = 117,
    updated_at = NOW()
WHERE course_id = 'CC_046';

UPDATE golf_courses
SET address = '경기도 화성시 정남면 세자로 286',
    lat = 37.187079,
    lon = 126.984143,
    grid_x = 60,
    grid_y = 118,
    updated_at = NOW()
WHERE course_id = 'CC_047';

COMMIT;

SELECT course_id, name, address, lat, lon, grid_x, grid_y
FROM golf_courses
WHERE course_id IN ('CC_046', 'CC_047')
ORDER BY course_id;
