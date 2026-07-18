-- Golf Windy 운영 데이터 보정 (배치 4)
-- 대상: 인천권 명칭/주소 일치가 명확한 코스
-- 실행 위치: Railway Postgres SQL Console

BEGIN;

UPDATE golf_courses
SET address = '인천광역시 인천시 서구 도요지로 37',
    lat = 37.561899,
    lon = 126.653660,
    grid_x = 54,
    grid_y = 127,
    updated_at = NOW()
WHERE course_id = 'CC_164';

UPDATE golf_courses
SET address = '인천광역시 인천시 연수구 능허대로 236',
    lat = 37.414871,
    lon = 126.650562,
    grid_x = 54,
    grid_y = 123,
    updated_at = NOW()
WHERE course_id = 'CC_166';

COMMIT;

SELECT course_id, name, address, lat, lon, grid_x, grid_y
FROM golf_courses
WHERE course_id IN ('CC_164', 'CC_166')
ORDER BY course_id;
