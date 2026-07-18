-- Golf Windy 운영 데이터 보정 (배치 2)
-- 대상: 용인권 잔여 좌표 오류 코스
-- 실행 위치: Railway Postgres SQL Console

BEGIN;

UPDATE golf_courses
SET address = '경기도 용인시 처인구 남사읍 전나무골길2번길 94',
    lat = 37.157129,
    lon = 127.130567,
    grid_x = 63,
    grid_y = 118,
    updated_at = NOW()
WHERE course_id = 'CC_017';

UPDATE golf_courses
SET address = '경기도 용인시 기흥구 중부대로 495',
    lat = 37.278880,
    lon = 127.120922,
    grid_x = 62,
    grid_y = 121,
    updated_at = NOW()
WHERE course_id = 'CC_019';

UPDATE golf_courses
SET address = '경기도 용인시 기흥구 흥덕4로 77',
    lat = 37.285065,
    lon = 127.085173,
    grid_x = 62,
    grid_y = 121,
    updated_at = NOW()
WHERE course_id = 'CC_021';

UPDATE golf_courses
SET address = '경기도 용인시 기흥구 구교동로 151',
    lat = 37.307079,
    lon = 127.123076,
    grid_x = 62,
    grid_y = 121,
    updated_at = NOW()
WHERE course_id = 'CC_022';

UPDATE golf_courses
SET address = '경기도 용인시 기흥구 기흥단지로 398',
    lat = 37.217619,
    lon = 127.136888,
    grid_x = 63,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_023';

UPDATE golf_courses
SET address = '경기도 용인시 기흥구 석성로521번길 169',
    lat = 37.302810,
    lon = 127.166788,
    grid_x = 63,
    grid_y = 121,
    updated_at = NOW()
WHERE course_id = 'CC_024';

UPDATE golf_courses
SET address = '경기도 용인시 기흥구 사은로 163',
    lat = 37.263940,
    lon = 127.126196,
    grid_x = 62,
    grid_y = 120,
    updated_at = NOW()
WHERE course_id = 'CC_026';

UPDATE golf_courses
SET address = '경기도 용인시 처인구 이동읍 이원로 225',
    lat = 37.181316,
    lon = 127.247532,
    grid_x = 65,
    grid_y = 118,
    updated_at = NOW()
WHERE course_id = 'CC_027';

UPDATE golf_courses
SET address = '경기도 용인시 처인구 백옥대로 860-38',
    lat = 37.215329,
    lon = 127.220054,
    grid_x = 64,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_028';

UPDATE golf_courses
SET address = '경기도 용인시 처인구 양지읍 양대로 290',
    lat = 37.254532,
    lon = 127.288950,
    grid_x = 65,
    grid_y = 120,
    updated_at = NOW()
WHERE course_id = 'CC_029';

UPDATE golf_courses
SET address = '경기도 용인시 처인구 이동읍 기흥단지로 579',
    lat = 37.219260,
    lon = 127.151394,
    grid_x = 63,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_031';

UPDATE golf_courses
SET address = '경기도 용인시 기흥구 기흥단지로 224',
    lat = 37.223524,
    lon = 127.119046,
    grid_x = 62,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_032';

UPDATE golf_courses
SET address = '경기도 용인시 처인구 포곡읍 에버랜드로562번길 69',
    lat = 37.294519,
    lon = 127.185728,
    grid_x = 63,
    grid_y = 121,
    updated_at = NOW()
WHERE course_id = 'CC_036';

UPDATE golf_courses
SET address = '경기도 용인시 처인구 이동읍 백자로 369',
    lat = 37.204093,
    lon = 127.184254,
    grid_x = 63,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_040';

UPDATE golf_courses
SET address = '경기도 용인시 처인구 이동읍 백자로 450',
    lat = 37.186678,
    lon = 127.188561,
    grid_x = 64,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_041';

COMMIT;

SELECT course_id, name, address, lat, lon, grid_x, grid_y
FROM golf_courses
WHERE course_id IN (
  'CC_017', 'CC_019', 'CC_021', 'CC_022', 'CC_023',
  'CC_024', 'CC_026', 'CC_027', 'CC_028', 'CC_029',
  'CC_031', 'CC_032', 'CC_036', 'CC_040', 'CC_041'
)
ORDER BY course_id;
