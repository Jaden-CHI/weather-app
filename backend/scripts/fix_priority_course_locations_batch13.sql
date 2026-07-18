-- 2026-07-05
-- 고양권 추가 좌표 보정

UPDATE golf_courses
SET
    address = '경기도 고양시 덕양구 고양대로1643번길 164',
    lat = 37.657494,
    lon = 126.863513,
    grid_x = 58,
    grid_y = 129,
    updated_at = NOW()
WHERE course_id = 'CC_010';

UPDATE golf_courses
SET
    address = '경기도 고양시 덕양구 흥도로 304-23',
    lat = 37.636880,
    lon = 126.858463,
    grid_x = 58,
    grid_y = 128,
    updated_at = NOW()
WHERE course_id = 'CC_012';

UPDATE golf_courses
SET
    address = '경기도 고양시 덕양구 혜음로 301',
    lat = 37.720588,
    lon = 126.894884,
    grid_x = 58,
    grid_y = 130,
    updated_at = NOW()
WHERE course_id = 'CC_014';

UPDATE golf_courses
SET
    address = '경기도 고양시 덕양구 고양대로 1591',
    lat = 37.652036,
    lon = 126.863195,
    grid_x = 58,
    grid_y = 129,
    updated_at = NOW()
WHERE course_id = 'CC_016';
