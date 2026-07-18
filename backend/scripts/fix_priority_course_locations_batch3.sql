-- Golf Windy 운영 데이터 보정 (배치 3)
-- 대상: 명칭/주소 일치가 명확한 추가 코스
-- 실행 위치: Railway Postgres SQL Console

BEGIN;

UPDATE golf_courses
SET address = '경기도 안성시 보개면 보삼로 302',
    lat = 37.095410,
    lon = 127.341550,
    grid_x = 66,
    grid_y = 117,
    updated_at = NOW()
WHERE course_id = 'CC_094';

UPDATE golf_courses
SET address = '경기도 안성시 양성면 교동길 19-70',
    lat = 37.075410,
    lon = 127.195026,
    grid_x = 64,
    grid_y = 116,
    updated_at = NOW()
WHERE course_id = 'CC_103';

UPDATE golf_courses
SET address = '제주특별자치도 제주시 오라남로 130-16(오라이동)',
    lat = 33.448082,
    lon = 126.513306,
    grid_x = 52,
    grid_y = 37,
    updated_at = NOW()
WHERE course_id = 'CC_513';

COMMIT;

SELECT course_id, name, address, lat, lon, grid_x, grid_y
FROM golf_courses
WHERE course_id IN ('CC_094', 'CC_103', 'CC_513')
ORDER BY course_id;
