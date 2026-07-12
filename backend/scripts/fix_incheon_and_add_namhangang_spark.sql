-- Golf Windy 운영 데이터 보정
-- 대상: 인천권 워커 원본 좌표 동기화 + 남한강에스파크CC 신규 등록
-- 실행 위치: Railway Postgres SQL Console

BEGIN;

UPDATE golf_courses
SET
    address = '인천광역시 검단구 자원순환로260번길 46',
    lat = 37.572663,
    lon = 126.643579,
    grid_x = 54,
    grid_y = 127,
    updated_at = NOW()
WHERE course_id = 'CC_171';

UPDATE golf_courses
SET
    address = '인천광역시 연수구 인천신항대로 1120',
    lat = 37.353972,
    lon = 126.592109,
    grid_x = 53,
    grid_y = 122,
    updated_at = NOW()
WHERE course_id = 'CC_172';

UPDATE golf_courses
SET
    address = '인천광역시 영종구 영종해안남로321번길 184',
    lat = 37.434465,
    lon = 126.455115,
    grid_x = 51,
    grid_y = 124,
    updated_at = NOW()
WHERE course_id = 'CC_174';

UPDATE golf_courses
SET
    address = '인천광역시 강화군 삼산면 어류정길177번길 15',
    lat = 37.653656,
    lon = 126.344637,
    grid_x = 49,
    grid_y = 129,
    updated_at = NOW()
WHERE course_id = 'CC_173';

UPDATE golf_courses
SET
    address = '인천광역시 강화군 길상면 해안남로 392',
    lat = 37.603586,
    lon = 126.514548,
    grid_x = 52,
    grid_y = 127,
    updated_at = NOW()
WHERE course_id = 'CC_175';

UPDATE golf_courses
SET
    address = '인천광역시 연수구 아카데미로 209',
    lat = 37.380495,
    lon = 126.624395,
    grid_x = 54,
    grid_y = 123,
    updated_at = NOW()
WHERE course_id = 'CC_413';

INSERT INTO golf_courses (
    course_id,
    name,
    name_short,
    region,
    address,
    lat,
    lon,
    grid_x,
    grid_y,
    holes,
    phone,
    website,
    public_data_id,
    golfzon_id,
    golfzon_url,
    golfzon_linked,
    data_source
) VALUES (
    'CC_521',
    '남한강에스파크CC',
    '남한강에스파크CC',
    '강원',
    '강원특별자치도 원주시 부론면 장뜰길 154',
    37.213654,
    127.765457,
    74,
    119,
    27,
    NULL,
    'http://nhgsparkresort.com/',
    NULL,
    NULL,
    NULL,
    FALSE,
    'PUBLIC_DATA'
)
ON CONFLICT (course_id) DO UPDATE SET
    name = EXCLUDED.name,
    name_short = EXCLUDED.name_short,
    region = EXCLUDED.region,
    address = EXCLUDED.address,
    lat = EXCLUDED.lat,
    lon = EXCLUDED.lon,
    grid_x = EXCLUDED.grid_x,
    grid_y = EXCLUDED.grid_y,
    holes = EXCLUDED.holes,
    phone = EXCLUDED.phone,
    website = EXCLUDED.website,
    public_data_id = EXCLUDED.public_data_id,
    golfzon_id = EXCLUDED.golfzon_id,
    golfzon_url = EXCLUDED.golfzon_url,
    golfzon_linked = EXCLUDED.golfzon_linked,
    data_source = EXCLUDED.data_source,
    updated_at = NOW();

COMMIT;

SELECT
    course_id,
    name,
    address,
    lat,
    lon,
    grid_x,
    grid_y,
    holes
FROM golf_courses
WHERE course_id IN ('CC_171', 'CC_172', 'CC_173', 'CC_174', 'CC_175', 'CC_413', 'CC_521')
ORDER BY course_id;
