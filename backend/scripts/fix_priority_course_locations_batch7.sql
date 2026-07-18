-- Golf Windy 운영 데이터 보정 (배치 7)
-- 대상: 여주권 주소 일치 기반 추가 보정 코스
-- 실행 위치: Railway Postgres SQL Console

BEGIN;

UPDATE golf_courses
SET address = '경기도 여주시 가남읍 송삼로 191(가남면 송림리 214)',
    lat = 37.179062,
    lon = 127.633301,
    grid_x = 71,
    grid_y = 118,
    updated_at = NOW()
WHERE course_id = 'CC_126';

UPDATE golf_courses
SET address = '경기도 여주시 북내면 운촌길 254(북내면 운촌리 산40)',
    lat = 37.332863,
    lon = 127.730972,
    grid_x = 73,
    grid_y = 122,
    updated_at = NOW()
WHERE course_id = 'CC_132';

UPDATE golf_courses
SET address = '경기도 여주시 강천면 부평로 580(강천면 부평리 산47-1)',
    lat = 37.302539,
    lon = 127.746302,
    grid_x = 73,
    grid_y = 121,
    updated_at = NOW()
WHERE course_id = 'CC_133';

UPDATE golf_courses
SET address = '경기도 여주시 명품1로 76(여주읍 연라리 산67-1 일원)',
    lat = 37.250660,
    lon = 127.617635,
    grid_x = 71,
    grid_y = 120,
    updated_at = NOW()
WHERE course_id = 'CC_134';

UPDATE golf_courses
SET address = '경기도 여주시 점동면 점동로 181(점동면 사곡리 산16-10)',
    lat = 37.204587,
    lon = 127.685398,
    grid_x = 72,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_138';

COMMIT;

SELECT course_id, name, address, lat, lon, grid_x, grid_y
FROM golf_courses
WHERE course_id IN ('CC_126', 'CC_132', 'CC_133', 'CC_134', 'CC_138')
ORDER BY course_id;
