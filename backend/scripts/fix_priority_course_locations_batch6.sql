-- Golf Windy 운영 데이터 보정 (배치 6)
-- 대상: 여주권 주소 일치 기반 보정 코스
-- 실행 위치: Railway Postgres SQL Console

BEGIN;

UPDATE golf_courses
SET address = '경기도 여주시 가여로 532(여주읍 하거리 산49)',
    lat = 37.226956,
    lon = 127.627459,
    grid_x = 71,
    grid_y = 120,
    updated_at = NOW()
WHERE course_id = 'CC_121';

UPDATE golf_courses
SET address = '경기도 여주시 점동면 소피아그린길 84(점동면 현수리 산13)',
    lat = 37.177909,
    lon = 127.707740,
    grid_x = 73,
    grid_y = 118,
    updated_at = NOW()
WHERE course_id = 'CC_122';

UPDATE golf_courses
SET address = '경기도 여주시 가남읍 솔모로그린길 171(가남면 양귀리 산69)',
    lat = 37.191521,
    lon = 127.580234,
    grid_x = 70,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_123';

UPDATE golf_courses
SET address = '경기도 여주시 가남읍 자유그린길 69(가남면 삼군리 산44외)',
    lat = 37.208563,
    lon = 127.571733,
    grid_x = 70,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_125';

UPDATE golf_courses
SET address = '경기도 여주시 가남읍 아리지그린길 68(가남면 안금리 산103, 양귀리 산10 일원)',
    lat = 37.214134,
    lon = 127.595318,
    grid_x = 71,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_127';

UPDATE golf_courses
SET address = '경기도 여주시 금사면 장흥로 416(금사면 장흥리 산1)',
    lat = 37.386513,
    lon = 127.491501,
    grid_x = 69,
    grid_y = 123,
    updated_at = NOW()
WHERE course_id = 'CC_128';

UPDATE golf_courses
SET address = '경기도 여주시 산북면 광여로 1115(산북면 상품리 산108)',
    lat = 37.401798,
    lon = 127.421741,
    grid_x = 67,
    grid_y = 123,
    updated_at = NOW()
WHERE course_id = 'CC_129';

UPDATE golf_courses
SET address = '경기도 여주시 대신면 고달사로 67(대신면 상구리 산11-1)',
    lat = 37.384435,
    lon = 127.647941,
    grid_x = 71,
    grid_y = 123,
    updated_at = NOW()
WHERE course_id = 'CC_130';

UPDATE golf_courses
SET address = '경기도 여주시 강천면 강문로 872(강천면 부평리 산109-1 일원 )',
    lat = 37.268494,
    lon = 127.737065,
    grid_x = 73,
    grid_y = 120,
    updated_at = NOW()
WHERE course_id = 'CC_137';

COMMIT;

SELECT course_id, name, address, lat, lon, grid_x, grid_y
FROM golf_courses
WHERE course_id IN (
  'CC_121', 'CC_122', 'CC_123', 'CC_125', 'CC_127',
  'CC_128', 'CC_129', 'CC_130', 'CC_137'
)
ORDER BY course_id;
