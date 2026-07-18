-- Golf Windy 운영 데이터 보정
-- 대상: 드림파크 + 상위 위험 용인권 좌표 오류 코스
-- 실행 위치: Railway Postgres SQL Console

BEGIN;

UPDATE golf_courses
SET address = '인천광역시 검단구 자원순환로260번길 46',
    lat = 37.572663,
    lon = 126.643579,
    grid_x = 54,
    grid_y = 127,
    updated_at = NOW()
WHERE course_id = 'CC_171';

UPDATE golf_courses
SET address = '경기도 용인시 처인구 백암면 고안로51번길 205',
    lat = 37.145852,
    lon = 127.419758,
    grid_x = 68,
    grid_y = 118,
    updated_at = NOW()
WHERE course_id = 'CC_039';

UPDATE golf_courses
SET address = '경기도 용인시 처인구 백암면 황새울로 255',
    lat = 37.110824,
    lon = 127.344149,
    grid_x = 66,
    grid_y = 117,
    updated_at = NOW()
WHERE course_id = 'CC_037';

UPDATE golf_courses
SET address = '경기도 용인시 처인구 원삼면 보개원삼로1534번길 40',
    lat = 37.134154,
    lon = 127.326002,
    grid_x = 66,
    grid_y = 117,
    updated_at = NOW()
WHERE course_id = 'CC_030';

UPDATE golf_courses
SET address = '경기도 용인시 처인구 원삼면 죽양대로2000번길 60',
    lat = 37.216065,
    lon = 127.336554,
    grid_x = 66,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_033';

UPDATE golf_courses
SET address = '경기도 용인시 처인구 남사읍 봉무로153번길 79',
    lat = 37.133066,
    lon = 127.141031,
    grid_x = 63,
    grid_y = 117,
    updated_at = NOW()
WHERE course_id = 'CC_020';

UPDATE golf_courses
SET address = '경기도 용인시 처인구 양지읍 남평로 112',
    lat = 37.217907,
    lon = 127.295007,
    grid_x = 65,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_018';

UPDATE golf_courses
SET address = '경기도 용인시 처인구 남사읍 경기동로 628',
    lat = 37.129927,
    lon = 127.189791,
    grid_x = 64,
    grid_y = 117,
    updated_at = NOW()
WHERE course_id = 'CC_035';

UPDATE golf_courses
SET address = '경기도 용인시 처인구 이동읍 화산로 239',
    lat = 37.154507,
    lon = 127.233616,
    grid_x = 64,
    grid_y = 118,
    updated_at = NOW()
WHERE course_id = 'CC_034';

UPDATE golf_courses
SET address = '경기도 용인시 처인구 모현읍 능원로 181',
    lat = 37.319443,
    lon = 127.179144,
    grid_x = 63,
    grid_y = 121,
    updated_at = NOW()
WHERE course_id = 'CC_025';

COMMIT;

SELECT course_id, name, address, lat, lon, grid_x, grid_y
FROM golf_courses
WHERE course_id IN (
  'CC_171', 'CC_039', 'CC_037', 'CC_030', 'CC_033',
  'CC_020', 'CC_018', 'CC_035', 'CC_034', 'CC_025'
)
ORDER BY course_id;
