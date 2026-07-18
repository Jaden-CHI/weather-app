-- Golf Windy 운영 데이터 보정 (배치 8)
-- 대상: 여주권 잔여 코스 및 리브랜딩 반영 좌표
-- 실행 위치: Railway Postgres SQL Console

BEGIN;

UPDATE golf_courses
SET address = '경기도 여주시 월평로 78(여주읍 월송리 35-10)',
    lat = 37.278043,
    lon = 127.603539,
    grid_x = 70,
    grid_y = 120,
    updated_at = NOW()
WHERE course_id = 'CC_120';

UPDATE golf_courses
SET address = '경기도 여주시 가남읍 금강그린길 84',
    lat = 37.243091,
    lon = 127.602029,
    grid_x = 70,
    grid_y = 120,
    updated_at = NOW()
WHERE course_id = 'CC_124';

UPDATE golf_courses
SET address = '경기도 여주시 여양로 530(북내면 신남리 산30-2)',
    lat = 37.329025,
    lon = 127.656093,
    grid_x = 72,
    grid_y = 122,
    updated_at = NOW()
WHERE course_id = 'CC_135';

COMMIT;

SELECT course_id, name, address, lat, lon, grid_x, grid_y
FROM golf_courses
WHERE course_id IN ('CC_120', 'CC_124', 'CC_135')
ORDER BY course_id;
