-- Golf Windy 운영 데이터 보정 (배치 9)
-- 대상: 1.2.3 / CLUBD 금강 좌표 보정
-- 실행 위치: Railway Postgres SQL Console

BEGIN;

UPDATE golf_courses
SET address = '경기도 고양시 덕양구 통일로 43-168',
    lat = 37.641468,
    lon = 126.906379,
    grid_x = 59,
    grid_y = 128,
    updated_at = NOW()
WHERE course_id = 'CC_013';

UPDATE golf_courses
SET address = '전라북도 익산시 웅포면 강변로 130',
    lat = 36.069815,
    lon = 126.891513,
    grid_x = 59,
    grid_y = 94,
    updated_at = NOW()
WHERE course_id = 'CC_488';

COMMIT;

SELECT course_id, name, address, lat, lon, grid_x, grid_y
FROM golf_courses
WHERE course_id IN ('CC_013', 'CC_488')
ORDER BY course_id;
