-- Golf Windy 골프장 좌표 전체 감사 자동 보정
-- 기준: 2026-07-17 Kakao Local 장소 검색, 8km 이상 drift 중 엄격 일치 후보
-- 주의: 주소는 보존하고 lat/lon/grid_x/grid_y만 갱신합니다.

BEGIN;

-- CC_014 올림픽 골프장 | 8.9km | 올림픽CC
UPDATE golf_courses
SET
    lat = 37.721864,
    lon = 126.893017,
    grid_x = 58,
    grid_y = 130,
    updated_at = NOW()
WHERE course_id = 'CC_014';

-- CC_018 양지파인CC | 10.7km | 양지파인GC
UPDATE golf_courses
SET
    lat = 37.217907,
    lon = 127.295007,
    grid_x = 65,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_018';

-- CC_020 플라자CC | 12.4km | 플라자CC 용인
UPDATE golf_courses
SET
    lat = 37.133066,
    lon = 127.141031,
    grid_x = 63,
    grid_y = 117,
    updated_at = NOW()
WHERE course_id = 'CC_020';

-- CC_021 태광CC | 9.5km | 태광CC
UPDATE golf_courses
SET
    lat = 37.285065,
    lon = 127.085173,
    grid_x = 62,
    grid_y = 121,
    updated_at = NOW()
WHERE course_id = 'CC_021';

-- CC_022 한성CC | 8.8km | 한성CC
UPDATE golf_courses
SET
    lat = 37.307079,
    lon = 127.123076,
    grid_x = 62,
    grid_y = 121,
    updated_at = NOW()
WHERE course_id = 'CC_022';

-- CC_025 레이크사이드CC | 8.7km | 레이크사이드CC
UPDATE golf_courses
SET
    lat = 37.319443,
    lon = 127.179144,
    grid_x = 63,
    grid_y = 121,
    updated_at = NOW()
WHERE course_id = 'CC_025';

-- CC_029 아시아나CC | 10.0km | 아시아나CC
UPDATE golf_courses
SET
    lat = 37.254532,
    lon = 127.288950,
    grid_x = 65,
    grid_y = 120,
    updated_at = NOW()
WHERE course_id = 'CC_029';

-- CC_030 블루원용인CC | 17.7km | 블루원 용인CC
UPDATE golf_courses
SET
    lat = 37.134154,
    lon = 127.326002,
    grid_x = 66,
    grid_y = 117,
    updated_at = NOW()
WHERE course_id = 'CC_030';

-- CC_033 지산CC | 14.3km | 지산CC
UPDATE golf_courses
SET
    lat = 37.216065,
    lon = 127.336554,
    grid_x = 66,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_033';

-- CC_034 화산CC | 10.8km | 화산CC
UPDATE golf_courses
SET
    lat = 37.154507,
    lon = 127.233616,
    grid_x = 64,
    grid_y = 118,
    updated_at = NOW()
WHERE course_id = 'CC_034';

-- CC_035 한림용인CC | 12.4km | 한림용인CC
UPDATE golf_courses
SET
    lat = 37.129927,
    lon = 127.189791,
    grid_x = 64,
    grid_y = 117,
    updated_at = NOW()
WHERE course_id = 'CC_035';

-- CC_037 용인CC | 20.7km | 용인CC
UPDATE golf_courses
SET
    lat = 37.110824,
    lon = 127.344149,
    grid_x = 66,
    grid_y = 117,
    updated_at = NOW()
WHERE course_id = 'CC_037';

-- CC_039 써닝포인트CC | 23.9km | 써닝포인트CC
UPDATE golf_courses
SET
    lat = 37.145852,
    lon = 127.419758,
    grid_x = 68,
    grid_y = 118,
    updated_at = NOW()
WHERE course_id = 'CC_039';

-- CC_043 리베라CC | 25.0km | 리베라CC
UPDATE golf_courses
SET
    lat = 37.190282,
    lon = 127.112765,
    grid_x = 62,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_043';

-- CC_044 기흥CC | 27.9km | 기흥CC
UPDATE golf_courses
SET
    lat = 37.191360,
    lon = 127.146529,
    grid_x = 63,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_044';

-- CC_045 발리오스CC | 9.7km | 발리오스CC
UPDATE golf_courses
SET
    lat = 37.115608,
    lon = 126.860830,
    grid_x = 58,
    grid_y = 117,
    updated_at = NOW()
WHERE course_id = 'CC_045';

-- CC_046 발리오스대중 | 9.7km | 발리오스CC
UPDATE golf_courses
SET
    lat = 37.115608,
    lon = 126.860830,
    grid_x = 58,
    grid_y = 117,
    updated_at = NOW()
WHERE course_id = 'CC_046';

-- CC_047 라비돌대중 | 13.6km | 라비돌CC
UPDATE golf_courses
SET
    lat = 37.187079,
    lon = 126.984143,
    grid_x = 60,
    grid_y = 118,
    updated_at = NOW()
WHERE course_id = 'CC_047';

-- CC_048 상록GC | 26.8km | 화성상록GC
UPDATE golf_courses
SET
    lat = 37.197115,
    lon = 127.133373,
    grid_x = 63,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_048';

-- CC_053 양주C.C | 12.3km | 양주CC
UPDATE golf_courses
SET
    lat = 37.645332,
    lon = 127.355948,
    grid_x = 66,
    grid_y = 129,
    updated_at = NOW()
WHERE course_id = 'CC_053';

-- CC_054 한림광릉C.C | 13.8km | 한림광릉CC
UPDATE golf_courses
SET
    lat = 37.758681,
    lon = 127.238494,
    grid_x = 64,
    grid_y = 131,
    updated_at = NOW()
WHERE course_id = 'CC_054';

-- CC_060 서서울 | 10.7km | 서서울CC
UPDATE golf_courses
SET
    lat = 37.731264,
    lon = 126.896452,
    grid_x = 58,
    grid_y = 130,
    updated_at = NOW()
WHERE course_id = 'CC_060';

-- CC_061 서원밸리 | 12.3km | 서원밸리CC
UPDATE golf_courses
SET
    lat = 37.824655,
    lon = 126.893300,
    grid_x = 58,
    grid_y = 132,
    updated_at = NOW()
WHERE course_id = 'CC_061';

-- CC_063 파주CC | 14.3km | 파주CC
UPDATE golf_courses
SET
    lat = 37.846293,
    lon = 126.900256,
    grid_x = 58,
    grid_y = 133,
    updated_at = NOW()
WHERE course_id = 'CC_063';

-- CC_064 베스트밸리 | 9.2km | 베스트밸리GC
UPDATE golf_courses
SET
    lat = 37.755172,
    lon = 126.884762,
    grid_x = 58,
    grid_y = 131,
    updated_at = NOW()
WHERE course_id = 'CC_064';

-- CC_065 노스팜 | 11.9km | 노스팜CC
UPDATE golf_courses
SET
    lat = 37.788866,
    lon = 126.911005,
    grid_x = 59,
    grid_y = 132,
    updated_at = NOW()
WHERE course_id = 'CC_065';

-- CC_071 그린힐컨트리클럽 | 17.6km | 그린힐CC
UPDATE golf_courses
SET
    lat = 37.354087,
    lon = 127.430343,
    grid_x = 68,
    grid_y = 122,
    updated_at = NOW()
WHERE course_id = 'CC_071';

-- CC_072 강남300컨트리클럽 | 8.4km | 강남300컨트리클럽
UPDATE golf_courses
SET
    lat = 37.385566,
    lon = 127.178357,
    grid_x = 63,
    grid_y = 123,
    updated_at = NOW()
WHERE course_id = 'CC_072';

-- CC_074 곤지암GC | 11.3km | 곤지암GC
UPDATE golf_courses
SET
    lat = 37.333248,
    lon = 127.295367,
    grid_x = 65,
    grid_y = 122,
    updated_at = NOW()
WHERE course_id = 'CC_074';

-- CC_081 송추cc | 12.0km | 송추CC
UPDATE golf_courses
SET
    lat = 37.794099,
    lon = 126.909807,
    grid_x = 59,
    grid_y = 132,
    updated_at = NOW()
WHERE course_id = 'CC_081';

-- CC_082 에이치원클럽 | 9.8km | 에이치원클럽
UPDATE golf_courses
SET
    lat = 37.188085,
    lon = 127.402873,
    grid_x = 67,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_082';

-- CC_083 뉴스프링빌C.C. | 13.2km | 뉴스프링빌CC 이천
UPDATE golf_courses
SET
    lat = 37.154016,
    lon = 127.419736,
    grid_x = 68,
    grid_y = 118,
    updated_at = NOW()
WHERE course_id = 'CC_083';

-- CC_084 비에이비스타C.C. | 10.3km | 비에이비스타CC
UPDATE golf_courses
SET
    lat = 37.180598,
    lon = 127.416809,
    grid_x = 67,
    grid_y = 118,
    updated_at = NOW()
WHERE course_id = 'CC_084';

-- CC_086 사우스스프링스C.C. | 10.8km | 사우스스프링스CC
UPDATE golf_courses
SET
    lat = 37.175696,
    lon = 127.451362,
    grid_x = 68,
    grid_y = 118,
    updated_at = NOW()
WHERE course_id = 'CC_086';

-- CC_089 이천마이다스골프앤리조트 | 13.2km | 마이다스레이크 이천 골프앤리조트
UPDATE golf_courses
SET
    lat = 37.177067,
    lon = 127.524471,
    grid_x = 69,
    grid_y = 118,
    updated_at = NOW()
WHERE course_id = 'CC_089';

-- CC_090 웰링턴C.C. | 11.6km | 웰링턴CC
UPDATE golf_courses
SET
    lat = 37.168817,
    lon = 127.420552,
    grid_x = 68,
    grid_y = 118,
    updated_at = NOW()
WHERE course_id = 'CC_090';

-- CC_092 파인크리크C.C | 10.1km | 파인크리크CC
UPDATE golf_courses
SET
    lat = 37.091886,
    lon = 127.235837,
    grid_x = 64,
    grid_y = 116,
    updated_at = NOW()
WHERE course_id = 'CC_092';

-- CC_093 골프클럽Q | 10.7km | 골프클럽Q
UPDATE golf_courses
SET
    lat = 37.046870,
    lon = 127.389626,
    grid_x = 67,
    grid_y = 116,
    updated_at = NOW()
WHERE course_id = 'CC_093';

-- CC_094 골프존카운티 안성H | 11.2km | 골프존카운티 안성H
UPDATE golf_courses
SET
    lat = 37.095410,
    lon = 127.341550,
    grid_x = 66,
    grid_y = 117,
    updated_at = NOW()
WHERE course_id = 'CC_094';

-- CC_095 마에스트로 CC | 10.9km | 마에스트로CC
UPDATE golf_courses
SET
    lat = 37.104761,
    lon = 127.260593,
    grid_x = 65,
    grid_y = 117,
    updated_at = NOW()
WHERE course_id = 'CC_095';

-- CC_096 안성컨트리클럽 | 12.3km | 안성컨트리클럽
UPDATE golf_courses
SET
    lat = 37.038661,
    lon = 127.413137,
    grid_x = 67,
    grid_y = 115,
    updated_at = NOW()
WHERE course_id = 'CC_096';

-- CC_098 신안컨트리클럽 | 10.3km | 신안CC
UPDATE golf_courses
SET
    lat = 37.097504,
    lon = 127.251332,
    grid_x = 65,
    grid_y = 117,
    updated_at = NOW()
WHERE course_id = 'CC_098';

-- CC_103 골프존카운티 안성W | 10.6km | 골프존카운티 안성W
UPDATE golf_courses
SET
    lat = 37.075410,
    lon = 127.195026,
    grid_x = 64,
    grid_y = 116,
    updated_at = NOW()
WHERE course_id = 'CC_103';

-- CC_104 한림안성 | 11.0km | 한림안성CC
UPDATE golf_courses
SET
    lat = 37.084810,
    lon = 127.201096,
    grid_x = 64,
    grid_y = 116,
    updated_at = NOW()
WHERE course_id = 'CC_104';

-- CC_107 포천아도니스 C.C | 8.2km | 포천아도니스CC 퍼블릭
UPDATE golf_courses
SET
    lat = 37.966106,
    lon = 127.178701,
    grid_x = 63,
    grid_y = 135,
    updated_at = NOW()
WHERE course_id = 'CC_107';

-- CC_111 일동레이크골프클럽 | 11.1km | 일동레이크GC
UPDATE golf_courses
SET
    lat = 37.928620,
    lon = 127.319626,
    grid_x = 66,
    grid_y = 135,
    updated_at = NOW()
WHERE course_id = 'CC_111';

-- CC_118 더스타휴 컨트리클럽 | 18.9km | 더스타휴 골프앤리조트
UPDATE golf_courses
SET
    lat = 37.475717,
    lon = 127.701184,
    grid_x = 72,
    grid_y = 125,
    updated_at = NOW()
WHERE course_id = 'CC_118';

-- CC_122 소피아그린 | 14.7km | 소피아그린CC
UPDATE golf_courses
SET
    lat = 37.177909,
    lon = 127.707740,
    grid_x = 73,
    grid_y = 118,
    updated_at = NOW()
WHERE course_id = 'CC_122';

-- CC_123 솔모로 | 12.9km | 솔모로CC
UPDATE golf_courses
SET
    lat = 37.191521,
    lon = 127.580234,
    grid_x = 70,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_123';

-- CC_125 자유 | 11.6km | 자유CC
UPDATE golf_courses
SET
    lat = 37.208563,
    lon = 127.571733,
    grid_x = 70,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_125';

-- CC_126 빅토리아 | 13.2km | 빅토리아GC
UPDATE golf_courses
SET
    lat = 37.179062,
    lon = 127.633301,
    grid_x = 71,
    grid_y = 118,
    updated_at = NOW()
WHERE course_id = 'CC_126';

-- CC_127 아리지 | 10.1km | 아리지CC
UPDATE golf_courses
SET
    lat = 37.214134,
    lon = 127.595318,
    grid_x = 71,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_127';

-- CC_128 이포 | 16.2km | 이포CC
UPDATE golf_courses
SET
    lat = 37.386513,
    lon = 127.491501,
    grid_x = 69,
    grid_y = 123,
    updated_at = NOW()
WHERE course_id = 'CC_128';

-- CC_129 렉스필드 | 22.3km | 렉스필드CC
UPDATE golf_courses
SET
    lat = 37.401798,
    lon = 127.421741,
    grid_x = 67,
    grid_y = 123,
    updated_at = NOW()
WHERE course_id = 'CC_129';

-- CC_130 블루헤런 | 9.6km | 블루헤런컨트리클럽
UPDATE golf_courses
SET
    lat = 37.384435,
    lon = 127.647941,
    grid_x = 71,
    grid_y = 123,
    updated_at = NOW()
WHERE course_id = 'CC_130';

-- CC_132 스카이밸리 | 9.1km | 스카이밸리CC
UPDATE golf_courses
SET
    lat = 37.332863,
    lon = 127.730972,
    grid_x = 73,
    grid_y = 122,
    updated_at = NOW()
WHERE course_id = 'CC_132';

-- CC_133 캐슬파인 | 9.6km | 캐슬파인GC
UPDATE golf_courses
SET
    lat = 37.302539,
    lon = 127.746302,
    grid_x = 73,
    grid_y = 121,
    updated_at = NOW()
WHERE course_id = 'CC_133';

-- CC_136 360도 | 9.0km | 360도CC
UPDATE golf_courses
SET
    lat = 37.302384,
    lon = 127.739458,
    grid_x = 73,
    grid_y = 121,
    updated_at = NOW()
WHERE course_id = 'CC_136';

-- CC_137 여주썬밸리 | 9.4km | 여주썬밸리CC
UPDATE golf_courses
SET
    lat = 37.268494,
    lon = 127.737065,
    grid_x = 73,
    grid_y = 120,
    updated_at = NOW()
WHERE course_id = 'CC_137';

-- CC_138 페럼 | 11.2km | 페럼클럽
UPDATE golf_courses
SET
    lat = 37.204587,
    lon = 127.685398,
    grid_x = 72,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_138';

-- CC_139 ROUTE 52CC | 9.8km | 루트52컨트리클럽
UPDATE golf_courses
SET
    lat = 37.352855,
    lon = 127.724296,
    grid_x = 73,
    grid_y = 122,
    updated_at = NOW()
WHERE course_id = 'CC_139';

-- CC_141 썬힐G.C | 14.9km | 썬힐GC
UPDATE golf_courses
SET
    lat = 37.877047,
    lon = 127.351451,
    grid_x = 66,
    grid_y = 134,
    updated_at = NOW()
WHERE course_id = 'CC_141';

-- CC_147 크리스탈밸리C.C | 11.6km | 크리스탈밸리CC
UPDATE golf_courses
SET
    lat = 37.794092,
    lon = 127.387381,
    grid_x = 67,
    grid_y = 132,
    updated_at = NOW()
WHERE course_id = 'CC_147';

-- CC_148 리앤리C.C | 13.9km | 리앤리CC
UPDATE golf_courses
SET
    lat = 37.873095,
    lon = 127.362326,
    grid_x = 66,
    grid_y = 133,
    updated_at = NOW()
WHERE course_id = 'CC_148';

-- CC_150 자유로컨트리클럽 | 15.1km | 자유로CC
UPDATE golf_courses
SET
    lat = 38.002449,
    lon = 126.950985,
    grid_x = 59,
    grid_y = 136,
    updated_at = NOW()
WHERE course_id = 'CC_150';

-- CC_155 하이스트컨트리클럽 | 24.1km | 하이스트컨트리클럽
UPDATE golf_courses
SET
    lat = 35.139157,
    lon = 128.815035,
    grid_x = 93,
    grid_y = 75,
    updated_at = NOW()
WHERE course_id = 'CC_155';

-- CC_156 해라컨트리클럽 | 21.8km | 해라컨트리클럽
UPDATE golf_courses
SET
    lat = 35.155261,
    lon = 128.838155,
    grid_x = 94,
    grid_y = 75,
    updated_at = NOW()
WHERE course_id = 'CC_156';

-- CC_158 해운대비치골프앤리조트 | 14.1km | 해운대비치골프앤리조트 분양영업팀
UPDATE golf_courses
SET
    lat = 35.224905,
    lon = 129.220345,
    grid_x = 100,
    grid_y = 77,
    updated_at = NOW()
WHERE course_id = 'CC_158';

-- CC_159 기장동원로얄컨트리클럽 | 13.1km | 기장동원로얄CC
UPDATE golf_courses
SET
    lat = 35.252542,
    lon = 129.189224,
    grid_x = 100,
    grid_y = 77,
    updated_at = NOW()
WHERE course_id = 'CC_159';

-- CC_162 팔공컨트리클럽 | 17.1km | 팔공컨트리클럽
UPDATE golf_courses
SET
    lat = 35.990031,
    lon = 128.721494,
    grid_x = 91,
    grid_y = 93,
    updated_at = NOW()
WHERE course_id = 'CC_162';

-- CC_163 냉천컨트리클럽 | 8.7km | 냉천컨트리클럽
UPDATE golf_courses
SET
    lat = 35.796069,
    lon = 128.625184,
    grid_x = 89,
    grid_y = 89,
    updated_at = NOW()
WHERE course_id = 'CC_163';

-- CC_182 보라골프장 | 16.8km | 보라컨트리클럽
UPDATE golf_courses
SET
    lat = 35.493189,
    lon = 129.133791,
    grid_x = 99,
    grid_y = 83,
    updated_at = NOW()
WHERE course_id = 'CC_182';

-- CC_187 세종에머슨컨트리클럽 | 26.0km | 세종에머슨컨트리클럽
UPDATE golf_courses
SET
    lat = 36.697562,
    lon = 127.182814,
    grid_x = 64,
    grid_y = 108,
    updated_at = NOW()
WHERE course_id = 'CC_187';

-- CC_193 천룡 | 11.1km | 천룡CC
UPDATE golf_courses
SET
    lat = 36.947447,
    lon = 127.386730,
    grid_x = 67,
    grid_y = 113,
    updated_at = NOW()
WHERE course_id = 'CC_193';

-- CC_194 시그너스 | 26.2km | 시그너스컨트리클럽
UPDATE golf_courses
SET
    lat = 37.175613,
    lon = 127.741762,
    grid_x = 73,
    grid_y = 118,
    updated_at = NOW()
WHERE course_id = 'CC_194';

-- CC_195 떼제베 | 15.4km | 올데이청주떼제베CC
UPDATE golf_courses
SET
    lat = 36.665461,
    lon = 127.318959,
    grid_x = 66,
    grid_y = 107,
    updated_at = NOW()
WHERE course_id = 'CC_195';

-- CC_196 썬밸리 | 22.7km | 썬밸리CC
UPDATE golf_courses
SET
    lat = 37.035975,
    lon = 127.464874,
    grid_x = 68,
    grid_y = 115,
    updated_at = NOW()
WHERE course_id = 'CC_196';

-- CC_197 세레니티cc(구, 실크리버) | 13.8km | 세레니티CC
UPDATE golf_courses
SET
    lat = 36.546022,
    lon = 127.392179,
    grid_x = 67,
    grid_y = 105,
    updated_at = NOW()
WHERE course_id = 'CC_197';

-- CC_199 레인보우힐스 | 10.3km | 레인보우힐스CC
UPDATE golf_courses
SET
    lat = 37.026455,
    lon = 127.649271,
    grid_x = 72,
    grid_y = 115,
    updated_at = NOW()
WHERE course_id = 'CC_199';

-- CC_202 골드나인 | 11.9km | 골드나인CC
UPDATE golf_courses
SET
    lat = 36.616436,
    lon = 127.618228,
    grid_x = 71,
    grid_y = 106,
    updated_at = NOW()
WHERE course_id = 'CC_202';

-- CC_203 센테리움 | 13.2km | 센테리움CC
UPDATE golf_courses
SET
    lat = 37.030463,
    lon = 127.785932,
    grid_x = 74,
    grid_y = 115,
    updated_at = NOW()
WHERE course_id = 'CC_203';

-- CC_204 대호단양 | 14.3km | 대호단양CC
UPDATE golf_courses
SET
    lat = 37.089652,
    lon = 128.272660,
    grid_x = 82,
    grid_y = 117,
    updated_at = NOW()
WHERE course_id = 'CC_204';

-- CC_205 대영베이스 | 9.2km | 대영베이스컨트리클럽
UPDATE golf_courses
SET
    lat = 36.946809,
    lon = 127.838898,
    grid_x = 75,
    grid_y = 114,
    updated_at = NOW()
WHERE course_id = 'CC_205';

-- CC_207 오창에딘버러 | 11.8km | 오창에딘버러컨트리클럽
UPDATE golf_courses
SET
    lat = 36.736381,
    lon = 127.428033,
    grid_x = 68,
    grid_y = 109,
    updated_at = NOW()
WHERE course_id = 'CC_207';

-- CC_208 이븐데일 | 11.2km | 이븐데일CC
UPDATE golf_courses
SET
    lat = 36.682786,
    lon = 127.603655,
    grid_x = 71,
    grid_y = 108,
    updated_at = NOW()
WHERE course_id = 'CC_208';

-- CC_211 젠스필드 | 19.2km | 젠스필드CC
UPDATE golf_courses
SET
    lat = 37.041855,
    lon = 127.516003,
    grid_x = 69,
    grid_y = 115,
    updated_at = NOW()
WHERE course_id = 'CC_211';

-- CC_212 로얄포레 | 22.0km | 로얄포레 CC
UPDATE golf_courses
SET
    lat = 36.994812,
    lon = 127.677872,
    grid_x = 72,
    grid_y = 115,
    updated_at = NOW()
WHERE course_id = 'CC_212';

-- CC_213 대영힐스 | 8.1km | 대영힐스컨트리클럽
UPDATE golf_courses
SET
    lat = 36.950409,
    lon = 127.849688,
    grid_x = 75,
    grid_y = 114,
    updated_at = NOW()
WHERE course_id = 'CC_213';

-- CC_214 진양밸리 | 22.4km | 진양밸리GC
UPDATE golf_courses
SET
    lat = 37.033596,
    lon = 127.467244,
    grid_x = 68,
    grid_y = 115,
    updated_at = NOW()
WHERE course_id = 'CC_214';

-- CC_218 킹스데일 | 10.2km | 킹스데일GC
UPDATE golf_courses
SET
    lat = 37.017916,
    lon = 127.816493,
    grid_x = 74,
    grid_y = 115,
    updated_at = NOW()
WHERE course_id = 'CC_218';

-- CC_219 동촌 | 17.7km | 동촌GC
UPDATE golf_courses
SET
    lat = 37.056651,
    lon = 127.744528,
    grid_x = 73,
    grid_y = 116,
    updated_at = NOW()
WHERE course_id = 'CC_219';

-- CC_222 감곡cc | 21.0km | 감곡CC
UPDATE golf_courses
SET
    lat = 37.128996,
    lon = 127.698929,
    grid_x = 72,
    grid_y = 117,
    updated_at = NOW()
WHERE course_id = 'CC_222';

-- CC_225 일레븐 | 20.4km | 일레븐CC
UPDATE golf_courses
SET
    lat = 37.093621,
    lon = 127.735668,
    grid_x = 73,
    grid_y = 117,
    updated_at = NOW()
WHERE course_id = 'CC_225';

-- CC_228 천안상록골프장 | 17.2km | 천안상록CC
UPDATE golf_courses
SET
    lat = 36.741065,
    lon = 127.283241,
    grid_x = 65,
    grid_y = 109,
    updated_at = NOW()
WHERE course_id = 'CC_228';

-- CC_229 골프존카운티 천안 | 17.6km | 골프존카운티 천안
UPDATE golf_courses
SET
    lat = 36.803686,
    lon = 127.310981,
    grid_x = 66,
    grid_y = 110,
    updated_at = NOW()
WHERE course_id = 'CC_229';

-- CC_230 뉴데이컨트리클럽 | 13.9km | 마론CC
UPDATE golf_courses
SET
    lat = 36.866064,
    lon = 127.256977,
    grid_x = 65,
    grid_y = 112,
    updated_at = NOW()
WHERE course_id = 'CC_230';

-- CC_239 더힐 컨트리클럽 | 11.9km | 그늘집 더힐컨트리클럽
UPDATE golf_courses
SET
    lat = 36.277330,
    lon = 127.170573,
    grid_x = 64,
    grid_y = 99,
    updated_at = NOW()
WHERE course_id = 'CC_239';

-- CC_240 파인스톤 컨트리클럽 | 8.6km | 파인스톤CC
UPDATE golf_courses
SET
    lat = 36.964690,
    lon = 126.667658,
    grid_x = 55,
    grid_y = 114,
    updated_at = NOW()
WHERE course_id = 'CC_240';

-- CC_241 파나시아 골프클럽 | 13.3km | 파나시아골프클럽
UPDATE golf_courses
SET
    lat = 36.884132,
    lon = 126.794434,
    grid_x = 57,
    grid_y = 112,
    updated_at = NOW()
WHERE course_id = 'CC_241';

-- CC_242 에딘버러 컨트리클럽 | 15.3km | 에딘버러컨트리클럽
UPDATE golf_courses
SET
    lat = 36.152634,
    lon = 127.326304,
    grid_x = 66,
    grid_y = 96,
    updated_at = NOW()
WHERE course_id = 'CC_242';

-- CC_243 백제컨트리클럽 | 13.3km | 백제CC
UPDATE golf_courses
SET
    lat = 36.347551,
    lon = 126.790668,
    grid_x = 57,
    grid_y = 100,
    updated_at = NOW()
WHERE course_id = 'CC_243';

-- CC_245 골든베이골프&리조트 | 11.8km | 골든베이골프&리조트
UPDATE golf_courses
SET
    lat = 36.710103,
    lon = 126.172538,
    grid_x = 46,
    grid_y = 108,
    updated_at = NOW()
WHERE course_id = 'CC_245';

-- CC_246 스톤비치컨트리클럽 | 14.3km | 스톤비치
UPDATE golf_courses
SET
    lat = 36.687745,
    lon = 126.154028,
    grid_x = 46,
    grid_y = 108,
    updated_at = NOW()
WHERE course_id = 'CC_246';

-- CC_254 포항C.C | 22.8km | 포항cc
UPDATE golf_courses
SET
    lat = 36.223971,
    lon = 129.342176,
    grid_x = 102,
    grid_y = 99,
    updated_at = NOW()
WHERE course_id = 'CC_254';

-- CC_262 서라벌G.C | 18.7km | 서라벌골프클럽
UPDATE golf_courses
SET
    lat = 35.693016,
    lon = 129.274180,
    grid_x = 101,
    grid_y = 87,
    updated_at = NOW()
WHERE course_id = 'CC_262';

-- CC_263 골프존카운티 감포 | 25.3km | 골프존카운티 감포
UPDATE golf_courses
SET
    lat = 35.773169,
    lon = 129.486115,
    grid_x = 105,
    grid_y = 89,
    updated_at = NOW()
WHERE course_id = 'CC_263';

-- CC_265 선리치G.C | 10.3km | 선리치골프클럽
UPDATE golf_courses
SET
    lat = 35.948185,
    lon = 129.208485,
    grid_x = 100,
    grid_y = 93,
    updated_at = NOW()
WHERE course_id = 'CC_265';

-- CC_269 애플밸리C.C | 10.3km | 애플밸리컨트리클럽
UPDATE golf_courses
SET
    lat = 36.220874,
    lon = 128.057118,
    grid_x = 79,
    grid_y = 98,
    updated_at = NOW()
WHERE course_id = 'CC_269';

-- CC_270 포도C.C | 12.6km | 포도CC 코스관리동
UPDATE golf_courses
SET
    lat = 36.036233,
    lon = 128.057791,
    grid_x = 79,
    grid_y = 94,
    updated_at = NOW()
WHERE course_id = 'CC_270';

-- CC_271 남안동C.C | 14.9km | 남안동컨트리클럽
UPDATE golf_courses
SET
    lat = 36.477899,
    lon = 128.606641,
    grid_x = 89,
    grid_y = 104,
    updated_at = NOW()
WHERE course_id = 'CC_271';

-- CC_272 안동리버힐C.C | 16.3km | 안동리버힐CC
UPDATE golf_courses
SET
    lat = 36.489312,
    lon = 128.575579,
    grid_x = 88,
    grid_y = 104,
    updated_at = NOW()
WHERE course_id = 'CC_272';

-- CC_274 골프존카운티 선산 | 10.6km | 골프존카운티 선산
UPDATE golf_courses
SET
    lat = 36.161770,
    lon = 128.449947,
    grid_x = 86,
    grid_y = 97,
    updated_at = NOW()
WHERE course_id = 'CC_274';

-- CC_275 골프존카운티 구미 | 9.8km | 골프존카운티 구미
UPDATE golf_courses
SET
    lat = 36.157714,
    lon = 128.442579,
    grid_x = 86,
    grid_y = 97,
    updated_at = NOW()
WHERE course_id = 'CC_275';

-- CC_276 구미C.C | 13.9km | 구미CC
UPDATE golf_courses
SET
    lat = 36.169750,
    lon = 128.486843,
    grid_x = 87,
    grid_y = 97,
    updated_at = NOW()
WHERE course_id = 'CC_276';

-- CC_278 영천C.C | 10.7km | 오션힐스 영천CC
UPDATE golf_courses
SET
    lat = 36.047953,
    lon = 129.012366,
    grid_x = 96,
    grid_y = 95,
    updated_at = NOW()
WHERE course_id = 'CC_278';

-- CC_281 블루원상주골프리조트 | 21.0km | 블루원 상주CC
UPDATE golf_courses
SET
    lat = 36.335311,
    lon = 127.944369,
    grid_x = 77,
    grid_y = 100,
    updated_at = NOW()
WHERE course_id = 'CC_281';

-- CC_283 문경레저타운골프장 | 14.5km | 문경레저타운
UPDATE golf_courses
SET
    lat = 36.715462,
    lon = 128.161873,
    grid_x = 81,
    grid_y = 109,
    updated_at = NOW()
WHERE course_id = 'CC_283';

-- CC_284 대구C.C | 8.2km | 대구CC
UPDATE golf_courses
SET
    lat = 35.871477,
    lon = 128.812200,
    grid_x = 93,
    grid_y = 91,
    updated_at = NOW()
WHERE course_id = 'CC_284';

-- CC_289 엠스클럽의성 | 14.5km | 엠스클럽의성컨트리클럽
UPDATE golf_courses
SET
    lat = 36.281810,
    lon = 128.560713,
    grid_x = 88,
    grid_y = 99,
    updated_at = NOW()
WHERE course_id = 'CC_289';

-- CC_291 오션비치C.C | 8.4km | 오션비치CC 기숙사
UPDATE golf_courses
SET
    lat = 36.340175,
    lon = 129.373868,
    grid_x = 102,
    grid_y = 101,
    updated_at = NOW()
WHERE course_id = 'CC_291';

-- CC_294 펜타뷰골프클럽 | 15.5km | 펜타뷰골프클럽
UPDATE golf_courses
SET
    lat = 35.742129,
    lon = 128.861733,
    grid_x = 94,
    grid_y = 88,
    updated_at = NOW()
WHERE course_id = 'CC_294';

-- CC_300 마이다스 구미 골프아카데미 | 11.6km | 마이다스구미골프아카데미
UPDATE golf_courses
SET
    lat = 36.083290,
    lon = 128.469316,
    grid_x = 86,
    grid_y = 95,
    updated_at = NOW()
WHERE course_id = 'CC_300';

-- CC_306 용원컨트리클럽 | 18.1km | 용원골프클럽
UPDATE golf_courses
SET
    lat = 35.113571,
    lon = 128.823386,
    grid_x = 93,
    grid_y = 74,
    updated_at = NOW()
WHERE course_id = 'CC_306';

-- CC_308 진주컨트리클럽 | 11.4km | 진주컨트리클럽
UPDATE golf_courses
SET
    lat = 35.173318,
    lon = 128.233151,
    grid_x = 83,
    grid_y = 75,
    updated_at = NOW()
WHERE course_id = 'CC_308';

-- CC_310 서경타니CC | 11.6km | 서경타니CC
UPDATE golf_courses
SET
    lat = 35.099511,
    lon = 128.015890,
    grid_x = 79,
    grid_y = 73,
    updated_at = NOW()
WHERE course_id = 'CC_310';

-- CC_311 삼삼컨트리클럽 | 12.0km | 삼삼컨트리클럽
UPDATE golf_courses
SET
    lat = 35.110780,
    lon = 128.047619,
    grid_x = 80,
    grid_y = 74,
    updated_at = NOW()
WHERE course_id = 'CC_311';

-- CC_312 골프존카운티 사천 | 9.8km | 골프존카운티 사천
UPDATE golf_courses
SET
    lat = 35.015326,
    lon = 127.957557,
    grid_x = 78,
    grid_y = 72,
    updated_at = NOW()
WHERE course_id = 'CC_312';

-- CC_314 김해정산컨트리클럽 | 8.2km | 정산컨트리클럽
UPDATE golf_courses
SET
    lat = 35.255237,
    lon = 128.805608,
    grid_x = 93,
    grid_y = 77,
    updated_at = NOW()
WHERE course_id = 'CC_314';

-- CC_319 거제드비치골프클럽 | 15.9km | 드비치골프클럽
UPDATE golf_courses
SET
    lat = 35.015896,
    lon = 128.673939,
    grid_x = 91,
    grid_y = 72,
    updated_at = NOW()
WHERE course_id = 'CC_319';

-- CC_322 동부산컨트리클럽 | 13.6km | 동부산컨트리클럽
UPDATE golf_courses
SET
    lat = 35.362969,
    lon = 129.182504,
    grid_x = 100,
    grid_y = 80,
    updated_at = NOW()
WHERE course_id = 'CC_322';

-- CC_329 골프존카운티 경남 | 15.6km | 골프존카운티 경남
UPDATE golf_courses
SET
    lat = 35.308615,
    lon = 128.574095,
    grid_x = 89,
    grid_y = 78,
    updated_at = NOW()
WHERE course_id = 'CC_329';

-- CC_330 부곡컨트리클럽 | 13.0km | 부곡컨트리클럽
UPDATE golf_courses
SET
    lat = 35.450370,
    lon = 128.577899,
    grid_x = 89,
    grid_y = 81,
    updated_at = NOW()
WHERE course_id = 'CC_330';

-- CC_332 고성노벨컨트리클럽 | 13.1km | 고성노벨CC
UPDATE golf_courses
SET
    lat = 35.069860,
    lon = 128.405289,
    grid_x = 86,
    grid_y = 73,
    updated_at = NOW()
WHERE course_id = 'CC_332';

-- CC_336 사우스케이프오너스클럽 | 16.6km | 사우스케이프오너스클럽
UPDATE golf_courses
SET
    lat = 34.836476,
    lon = 128.074406,
    grid_x = 80,
    grid_y = 68,
    updated_at = NOW()
WHERE course_id = 'CC_336';

-- CC_342 클럽디거창 | 10.5km | 클럽디 거창
UPDATE golf_courses
SET
    lat = 35.591984,
    lon = 127.904807,
    grid_x = 77,
    grid_y = 84,
    updated_at = NOW()
WHERE course_id = 'CC_342';

-- CC_349 골프존카운티 순천 | 19.4km | 골프존카운티 순천
UPDATE golf_courses
SET
    lat = 35.044796,
    lon = 127.308179,
    grid_x = 66,
    grid_y = 72,
    updated_at = NOW()
WHERE course_id = 'CC_349';

-- CC_351 골드레이크CC | 16.3km | 골드레이크CC
UPDATE golf_courses
SET
    lat = 34.957950,
    lon = 126.875534,
    grid_x = 59,
    grid_y = 70,
    updated_at = NOW()
WHERE course_id = 'CC_351';

-- CC_352 해피니스CC | 11.3km | 해피니스CC 골프텔
UPDATE golf_courses
SET
    lat = 34.995930,
    lon = 126.832694,
    grid_x = 58,
    grid_y = 71,
    updated_at = NOW()
WHERE course_id = 'CC_352';

-- CC_359 광주CC | 11.5km | 광주컨트리클럽
UPDATE golf_courses
SET
    lat = 35.310823,
    lon = 127.170435,
    grid_x = 64,
    grid_y = 78,
    updated_at = NOW()
WHERE course_id = 'CC_359';

-- CC_361 보성CC | 13.9km | 보성CC
UPDATE golf_courses
SET
    lat = 34.816878,
    lon = 127.221098,
    grid_x = 65,
    grid_y = 67,
    updated_at = NOW()
WHERE course_id = 'CC_361';

-- CC_366 무등산CC | 10.3km | 무등산CC
UPDATE golf_courses
SET
    lat = 35.047410,
    lon = 126.935825,
    grid_x = 60,
    grid_y = 72,
    updated_at = NOW()
WHERE course_id = 'CC_366';

-- CC_367 JNJ골프리조트 | 14.2km | JNJ골프리조트 골프호텔
UPDATE golf_courses
SET
    lat = 34.798814,
    lon = 126.970122,
    grid_x = 60,
    grid_y = 66,
    updated_at = NOW()
WHERE course_id = 'CC_367';

-- CC_368 다산베아채 골프앤리조트 | 10.8km | 다산베아채골프앤리조트
UPDATE golf_courses
SET
    lat = 34.544999,
    lon = 126.758847,
    grid_x = 57,
    grid_y = 61,
    updated_at = NOW()
WHERE course_id = 'CC_368';

-- CC_370 파인비치골프링크스 | 33.6km | 파인비치골프링크스 오시아노코스
UPDATE golf_courses
SET
    lat = 34.697087,
    lon = 126.263830,
    grid_x = 48,
    grid_y = 64,
    updated_at = NOW()
WHERE course_id = 'CC_370';

-- CC_371 솔라시도CC | 23.3km | 솔라시도CC
UPDATE golf_courses
SET
    lat = 34.699388,
    lon = 126.395403,
    grid_x = 50,
    grid_y = 64,
    updated_at = NOW()
WHERE course_id = 'CC_371';

-- CC_372 아크로CC | 11.3km | 아크로CC
UPDATE golf_courses
SET
    lat = 34.871827,
    lon = 126.785323,
    grid_x = 57,
    grid_y = 68,
    updated_at = NOW()
WHERE course_id = 'CC_372';

-- CC_378 웨스트오션CC | 12.6km | 영광 웨스트오션CC
UPDATE golf_courses
SET
    lat = 35.355370,
    lon = 126.411435,
    grid_x = 50,
    grid_y = 79,
    updated_at = NOW()
WHERE course_id = 'CC_378';

-- CC_381 백양우리CC | 13.6km | 백양우리컨트리클럽
UPDATE golf_courses
SET
    lat = 35.423248,
    lon = 126.807002,
    grid_x = 57,
    grid_y = 80,
    updated_at = NOW()
WHERE course_id = 'CC_381';

-- CC_384 에버리스골프리조트 | 20.9km | 에버리스골프리조트
UPDATE golf_courses
SET
    lat = 33.371815,
    lon = 126.365667,
    grid_x = 50,
    grid_y = 35,
    updated_at = NOW()
WHERE course_id = 'CC_384';

-- CC_386 사이프러스 | 24.6km | 사이프러스골프&리조트
UPDATE golf_courses
SET
    lat = 33.413975,
    lon = 126.743194,
    grid_x = 57,
    grid_y = 36,
    updated_at = NOW()
WHERE course_id = 'CC_386';

-- CC_387 엘리시안 제주cc | 19.9km | 엘리시안 제주CC
UPDATE golf_courses
SET
    lat = 33.372334,
    lon = 126.380847,
    grid_x = 50,
    grid_y = 35,
    updated_at = NOW()
WHERE course_id = 'CC_387';

-- CC_391 세인트포CC | 19.4km | 아난티클럽제주
UPDATE golf_courses
SET
    lat = 33.520547,
    lon = 126.738607,
    grid_x = 57,
    grid_y = 38,
    updated_at = NOW()
WHERE course_id = 'CC_391';

-- CC_394 캐슬렉스제주GC | 21.9km | 캐슬렉스제주
UPDATE golf_courses
SET
    lat = 33.340253,
    lon = 126.348731,
    grid_x = 49,
    grid_y = 34,
    updated_at = NOW()
WHERE course_id = 'CC_394';

-- CC_395 크라운CC | 15.7km | 크라운CC가든
UPDATE golf_courses
SET
    lat = 33.531449,
    lon = 126.695971,
    grid_x = 56,
    grid_y = 39,
    updated_at = NOW()
WHERE course_id = 'CC_395';

-- CC_396 해비치CC | 19.4km | 해비치CC 제주
UPDATE golf_courses
SET
    lat = 33.358905,
    lon = 126.727311,
    grid_x = 56,
    grid_y = 35,
    updated_at = NOW()
WHERE course_id = 'CC_396';

-- CC_397 타미우스CC | 21.1km | 타미우스CC게스트하우스
UPDATE golf_courses
SET
    lat = 33.351630,
    lon = 126.388162,
    grid_x = 50,
    grid_y = 35,
    updated_at = NOW()
WHERE course_id = 'CC_397';

-- CC_398 라헨느 | 9.2km | 라헨느리조트
UPDATE golf_courses
SET
    lat = 33.453268,
    lon = 126.613849,
    grid_x = 54,
    grid_y = 37,
    updated_at = NOW()
WHERE course_id = 'CC_398';

-- CC_400 더클래식CC | 17.1km | 더클래식CC
UPDATE golf_courses
SET
    lat = 33.370641,
    lon = 126.679916,
    grid_x = 55,
    grid_y = 35,
    updated_at = NOW()
WHERE course_id = 'CC_400';

-- CC_401 스프링데일 | 11.1km | 스프링데일 골프앤리조트
UPDATE golf_courses
SET
    lat = 33.329551,
    lon = 126.638475,
    grid_x = 55,
    grid_y = 34,
    updated_at = NOW()
WHERE course_id = 'CC_401';

-- CC_402 에코랜드 | 14.2km | 에코랜드호텔
UPDATE golf_courses
SET
    lat = 33.451309,
    lon = 126.672330,
    grid_x = 55,
    grid_y = 37,
    updated_at = NOW()
WHERE course_id = 'CC_402';

-- CC_403 아덴힐 | 22.8km | 아덴힐CC
UPDATE golf_courses
SET
    lat = 33.347431,
    lon = 126.366926,
    grid_x = 50,
    grid_y = 35,
    updated_at = NOW()
WHERE course_id = 'CC_403';

-- CC_404 더헤븐 | 25.7km | 더헤븐CC
UPDATE golf_courses
SET
    lat = 37.228929,
    lon = 126.565398,
    grid_x = 53,
    grid_y = 119,
    updated_at = NOW()
WHERE course_id = 'CC_404';

-- CC_405 더 시에나 서울 컨트리클럽 | 13.5km | 더 시에나 서울 컨트리클럽
UPDATE golf_courses
SET
    lat = 37.335553,
    lon = 127.351826,
    grid_x = 66,
    grid_y = 122,
    updated_at = NOW()
WHERE course_id = 'CC_405';

-- CC_409 포웰CC 안성 | 12.2km | 포웰CC 안성
UPDATE golf_courses
SET
    lat = 37.117079,
    lon = 127.268737,
    grid_x = 65,
    grid_y = 117,
    updated_at = NOW()
WHERE course_id = 'CC_409';

-- CC_410 원더클럽 신라CC | 9.3km | 신라CC
UPDATE golf_courses
SET
    lat = 37.367157,
    lon = 127.696413,
    grid_x = 72,
    grid_y = 123,
    updated_at = NOW()
WHERE course_id = 'CC_410';

-- CC_411 마이다스밸리 청평 | 19.0km | 마이다스밸리 청평 골프클럽
UPDATE golf_courses
SET
    lat = 37.665776,
    lon = 127.458696,
    grid_x = 68,
    grid_y = 129,
    updated_at = NOW()
WHERE course_id = 'CC_411';

-- CC_418 엘리시안 강촌컨트리클럽 | 14.4km | 엘리시안 강촌CC
UPDATE golf_courses
SET
    lat = 37.829950,
    lon = 127.578575,
    grid_x = 70,
    grid_y = 133,
    updated_at = NOW()
WHERE course_id = 'CC_418';

-- CC_420 제이드팰리스 골프클럽 | 16.9km | 제이드팰리스GC
UPDATE golf_courses
SET
    lat = 37.830877,
    lon = 127.548492,
    grid_x = 70,
    grid_y = 133,
    updated_at = NOW()
WHERE course_id = 'CC_420';

-- CC_422 휘슬링락컨트리클럽 | 13.2km | 휘슬링락CC
UPDATE golf_courses
SET
    lat = 37.770116,
    lon = 127.678452,
    grid_x = 72,
    grid_y = 131,
    updated_at = NOW()
WHERE course_id = 'CC_422';

-- CC_423 오너스골프클럽 | 13.8km | 오너스GC
UPDATE golf_courses
SET
    lat = 37.771778,
    lon = 127.656247,
    grid_x = 71,
    grid_y = 131,
    updated_at = NOW()
WHERE course_id = 'CC_423';

-- CC_432 Oak Hills컨트리클럽 | 12.2km | 오크힐스CC
UPDATE golf_courses
SET
    lat = 37.407905,
    lon = 127.808903,
    grid_x = 74,
    grid_y = 124,
    updated_at = NOW()
WHERE course_id = 'CC_432';

-- CC_433 센추리21컨트리클럽 | 9.6km | 센추리21CC
UPDATE golf_courses
SET
    lat = 37.281450,
    lon = 127.842417,
    grid_x = 75,
    grid_y = 121,
    updated_at = NOW()
WHERE course_id = 'CC_433';

-- CC_435 센추리21퍼블릭 | 9.6km | 센추리21CC
UPDATE golf_courses
SET
    lat = 37.281450,
    lon = 127.842417,
    grid_x = 75,
    grid_y = 121,
    updated_at = NOW()
WHERE course_id = 'CC_435';

-- CC_436 파크밸리골프클럽 | 9.7km | 파크밸리골프클럽
UPDATE golf_courses
SET
    lat = 37.388932,
    lon = 128.013091,
    grid_x = 78,
    grid_y = 123,
    updated_at = NOW()
WHERE course_id = 'CC_436';

-- CC_440 메이플비치골프&리조트 | 8.8km | 메이플비치골프&리조트 에코가든
UPDATE golf_courses
SET
    lat = 37.746403,
    lon = 128.975845,
    grid_x = 94,
    grid_y = 131,
    updated_at = NOW()
WHERE course_id = 'CC_440';

-- CC_445 파인밸리컨트리클럽 | 8.9km | 파인밸리CC
UPDATE golf_courses
SET
    lat = 37.376372,
    lon = 129.205134,
    grid_x = 98,
    grid_y = 124,
    updated_at = NOW()
WHERE course_id = 'CC_445';

-- CC_446 블랙밸리컨트리클럽 | 27.0km | 블랙밸리CC
UPDATE golf_courses
SET
    lat = 37.218183,
    lon = 129.073434,
    grid_x = 96,
    grid_y = 120,
    updated_at = NOW()
WHERE course_id = 'CC_446';

-- CC_448 소노펠리체 컨트리클럽 비발디파크 마운틴 | 18.4km | 소노펠리체CC 비발디파크 마운틴
UPDATE golf_courses
SET
    lat = 37.652103,
    lon = 127.687106,
    grid_x = 72,
    grid_y = 129,
    updated_at = NOW()
WHERE course_id = 'CC_448';

-- CC_449 소노펠리체 컨트리클럽 비발디파크 이스트 | 18.1km | 소노펠리체CC 비발디파크 EAST
UPDATE golf_courses
SET
    lat = 37.666893,
    lon = 127.686397,
    grid_x = 72,
    grid_y = 129,
    updated_at = NOW()
WHERE course_id = 'CC_449';

-- CC_450 비콘힐스골프클럽 | 8.3km | 비콘힐스골프클럽
UPDATE golf_courses
SET
    lat = 37.623620,
    lon = 127.868501,
    grid_x = 75,
    grid_y = 128,
    updated_at = NOW()
WHERE course_id = 'CC_450';

-- CC_451 힐드로사이컨트리클럽 | 18.8km | 힐드로사이CC
UPDATE golf_courses
SET
    lat = 37.596285,
    lon = 127.716479,
    grid_x = 72,
    grid_y = 128,
    updated_at = NOW()
WHERE course_id = 'CC_451';

-- CC_453 세이지우드CC홍천 | 29.2km | 세이지우드CC 홍천
UPDATE golf_courses
SET
    lat = 37.886042,
    lon = 128.118477,
    grid_x = 79,
    grid_y = 134,
    updated_at = NOW()
WHERE course_id = 'CC_453';

-- CC_454 샤인데일골프&리조트 | 29.0km | 샤인데일골프&리조트
UPDATE golf_courses
SET
    lat = 37.674038,
    lon = 127.560317,
    grid_x = 70,
    grid_y = 129,
    updated_at = NOW()
WHERE course_id = 'CC_454';

-- CC_455 웰리힐리컨트리클럽 | 22.1km | 웰리힐리컨트리클럽
UPDATE golf_courses
SET
    lat = 37.473563,
    lon = 128.233823,
    grid_x = 81,
    grid_y = 125,
    updated_at = NOW()
WHERE course_id = 'CC_455';

-- CC_457 동원썬밸리컨트리클럽 | 17.1km | 동원썬밸리CC
UPDATE golf_courses
SET
    lat = 37.481432,
    lon = 127.791366,
    grid_x = 74,
    grid_y = 125,
    updated_at = NOW()
WHERE course_id = 'CC_457';

-- CC_458 알프스대영컨트리클럽 | 8.2km | 알프스대영컨트리클럽 골프빌리지
UPDATE golf_courses
SET
    lat = 37.463742,
    lon = 128.070696,
    grid_x = 79,
    grid_y = 125,
    updated_at = NOW()
WHERE course_id = 'CC_458';

-- CC_462 용평리조트골프클럽 | 41.2km | 용평CC
UPDATE golf_courses
SET
    lat = 37.645750,
    lon = 128.702122,
    grid_x = 89,
    grid_y = 129,
    updated_at = NOW()
WHERE course_id = 'CC_462';

-- CC_463 용평버치힐골프클럽 | 42.3km | 버치힐CC
UPDATE golf_courses
SET
    lat = 37.657712,
    lon = 128.704848,
    grid_x = 89,
    grid_y = 129,
    updated_at = NOW()
WHERE course_id = 'CC_463';

-- CC_467 알펜시아컨트리클럽 | 39.8km | 알펜시아CC
UPDATE golf_courses
SET
    lat = 37.654830,
    lon = 128.664409,
    grid_x = 89,
    grid_y = 129,
    updated_at = NOW()
WHERE course_id = 'CC_467';

-- CC_470 에콜리안정선골프장 | 17.7km | 에콜리안CC 정선
UPDATE golf_courses
SET
    lat = 37.221714,
    lon = 128.680995,
    grid_x = 89,
    grid_y = 120,
    updated_at = NOW()
WHERE course_id = 'CC_470';

-- CC_473 소노펠리체 컨트리클럽 델피노 | 18.9km | 소노펠리체CC 델피노
UPDATE golf_courses
SET
    lat = 38.209874,
    lon = 128.494681,
    grid_x = 85,
    grid_y = 141,
    updated_at = NOW()
WHERE course_id = 'CC_473';

-- CC_474 파인리즈컨트리클럽 | 15.6km | 파인리즈CC
UPDATE golf_courses
SET
    lat = 38.250401,
    lon = 128.540016,
    grid_x = 86,
    grid_y = 142,
    updated_at = NOW()
WHERE course_id = 'CC_474';

-- CC_477 포웰CC 프린세스 | 22.6km | 포웰CC프린세스
UPDATE golf_courses
SET
    lat = 36.649365,
    lon = 127.116178,
    grid_x = 62,
    grid_y = 107,
    updated_at = NOW()
WHERE course_id = 'CC_477';

-- CC_481 힐스카이CC | 10.1km | 힐스카이CC 경주지점
UPDATE golf_courses
SET
    lat = 35.910580,
    lon = 129.314386,
    grid_x = 101,
    grid_y = 92,
    updated_at = NOW()
WHERE course_id = 'CC_481';

-- CC_482 포웰CC 김해 | 9.6km | 포웰CC
UPDATE golf_courses
SET
    lat = 35.232208,
    lon = 128.783981,
    grid_x = 93,
    grid_y = 77,
    updated_at = NOW()
WHERE course_id = 'CC_482';

-- CC_483 전주월드컵골프장 | 8.7km | 전주월드컵골프장
UPDATE golf_courses
SET
    lat = 35.863831,
    lon = 127.064797,
    grid_x = 62,
    grid_y = 90,
    updated_at = NOW()
WHERE course_id = 'CC_483';

-- CC_484 군산CC | 11.0km | 군산CC
UPDATE golf_courses
SET
    lat = 35.894451,
    lon = 126.655089,
    grid_x = 55,
    grid_y = 90,
    updated_at = NOW()
WHERE course_id = 'CC_484';

-- CC_487 웅포컨트리클럽 | 14.5km | 웅포컨트리클럽
UPDATE golf_courses
SET
    lat = 36.067126,
    lon = 126.890764,
    grid_x = 59,
    grid_y = 94,
    updated_at = NOW()
WHERE course_id = 'CC_487';

-- CC_488 CLUBD 금강 | 14.8km | CLUBD금강
UPDATE golf_courses
SET
    lat = 36.069815,
    lon = 126.891513,
    grid_x = 59,
    grid_y = 94,
    updated_at = NOW()
WHERE course_id = 'CC_488';

-- CC_494 에스페란사GC | 11.5km | 에스페란사골프클럽
UPDATE golf_courses
SET
    lat = 35.807047,
    lon = 127.008099,
    grid_x = 61,
    grid_y = 88,
    updated_at = NOW()
WHERE course_id = 'CC_494';

-- CC_496 더나인골프클럽 | 13.9km | 더나인골프클럽
UPDATE golf_courses
SET
    lat = 35.795507,
    lon = 127.034436,
    grid_x = 61,
    grid_y = 88,
    updated_at = NOW()
WHERE course_id = 'CC_496';

-- CC_499 써미트CC | 10.6km | 써미트
UPDATE golf_courses
SET
    lat = 35.840857,
    lon = 127.325185,
    grid_x = 66,
    grid_y = 89,
    updated_at = NOW()
WHERE course_id = 'CC_499';

-- CC_500 무주덕유산CC | 14.6km | 무주덕유산CC
UPDATE golf_courses
SET
    lat = 35.886298,
    lon = 127.726053,
    grid_x = 73,
    grid_y = 90,
    updated_at = NOW()
WHERE course_id = 'CC_500';

-- CC_501 골프존카운티무주 | 19.6km | 골프존카운티 무주
UPDATE golf_courses
SET
    lat = 35.831322,
    lon = 127.636554,
    grid_x = 72,
    grid_y = 89,
    updated_at = NOW()
WHERE course_id = 'CC_501';

-- CC_506 고창CC | 20.2km | 고창CC
UPDATE golf_courses
SET
    lat = 35.516022,
    lon = 126.502247,
    grid_x = 52,
    grid_y = 82,
    updated_at = NOW()
WHERE course_id = 'CC_506';

-- CC_507 골프존카운티선운 | 8.2km | 골프존카운티 선운
UPDATE golf_courses
SET
    lat = 35.492188,
    lon = 126.643976,
    grid_x = 54,
    grid_y = 82,
    updated_at = NOW()
WHERE course_id = 'CC_507';

-- CC_509 롯데스카이힐 제주CC | 14.8km | 에스에스클럽 롯데스카이힐제주CC대식당
UPDATE golf_courses
SET
    lat = 33.287272,
    lon = 126.405279,
    grid_x = 50,
    grid_y = 33,
    updated_at = NOW()
WHERE course_id = 'CC_509';

-- CC_510 테디밸리골프앤리조트 | 20.1km | 테디밸리골프앤리조트
UPDATE golf_courses
SET
    lat = 33.292611,
    lon = 126.348527,
    grid_x = 49,
    grid_y = 33,
    updated_at = NOW()
WHERE course_id = 'CC_510';

-- CC_511 라온골프클럽 | 29.3km | 라온GC
UPDATE golf_courses
SET
    lat = 33.340552,
    lon = 126.279622,
    grid_x = 48,
    grid_y = 34,
    updated_at = NOW()
WHERE course_id = 'CC_511';

-- CC_512 SK핀크스 골프클럽 | 17.3km | 핀크스GC
UPDATE golf_courses
SET
    lat = 33.315328,
    lon = 126.388628,
    grid_x = 50,
    grid_y = 34,
    updated_at = NOW()
WHERE course_id = 'CC_512';

-- CC_515 플라자CC 제주 | 11.0km | 플라자CC 제주
UPDATE golf_courses
SET
    lat = 33.450554,
    lon = 126.633812,
    grid_x = 55,
    grid_y = 37,
    updated_at = NOW()
WHERE course_id = 'CC_515';

-- CC_516 부영CC | 18.4km | 부영CC
UPDATE golf_courses
SET
    lat = 33.358373,
    lon = 126.713560,
    grid_x = 56,
    grid_y = 35,
    updated_at = NOW()
WHERE course_id = 'CC_516';

-- CC_518 나인브릿지 | 17.4km | 나인브릿지CC
UPDATE golf_courses
SET
    lat = 33.341844,
    lon = 126.405415,
    grid_x = 50,
    grid_y = 34,
    updated_at = NOW()
WHERE course_id = 'CC_518';

-- CC_519 나인브릿지 퍼블릭 | 18.2km | 나인브릿지 퍼블릭
UPDATE golf_courses
SET
    lat = 33.343054,
    lon = 126.395513,
    grid_x = 50,
    grid_y = 35,
    updated_at = NOW()
WHERE course_id = 'CC_519';

COMMIT;

SELECT course_id, name, address, lat, lon, grid_x, grid_y, updated_at
FROM golf_courses
WHERE course_id IN ('CC_014', 'CC_018', 'CC_020', 'CC_021', 'CC_022', 'CC_025', 'CC_029', 'CC_030', 'CC_033', 'CC_034', 'CC_035', 'CC_037', 'CC_039', 'CC_043', 'CC_044', 'CC_045', 'CC_046', 'CC_047', 'CC_048', 'CC_053', 'CC_054', 'CC_060', 'CC_061', 'CC_063', 'CC_064', 'CC_065', 'CC_071', 'CC_072', 'CC_074', 'CC_081', 'CC_082', 'CC_083', 'CC_084', 'CC_086', 'CC_089', 'CC_090', 'CC_092', 'CC_093', 'CC_094', 'CC_095', 'CC_096', 'CC_098', 'CC_103', 'CC_104', 'CC_107', 'CC_111', 'CC_118', 'CC_122', 'CC_123', 'CC_125', 'CC_126', 'CC_127', 'CC_128', 'CC_129', 'CC_130', 'CC_132', 'CC_133', 'CC_136', 'CC_137', 'CC_138', 'CC_139', 'CC_141', 'CC_147', 'CC_148', 'CC_150', 'CC_155', 'CC_156', 'CC_158', 'CC_159', 'CC_162', 'CC_163', 'CC_182', 'CC_187', 'CC_193', 'CC_194', 'CC_195', 'CC_196', 'CC_197', 'CC_199', 'CC_202', 'CC_203', 'CC_204', 'CC_205', 'CC_207', 'CC_208', 'CC_211', 'CC_212', 'CC_213', 'CC_214', 'CC_218', 'CC_219', 'CC_222', 'CC_225', 'CC_228', 'CC_229', 'CC_230', 'CC_239', 'CC_240', 'CC_241', 'CC_242', 'CC_243', 'CC_245', 'CC_246', 'CC_254', 'CC_262', 'CC_263', 'CC_265', 'CC_269', 'CC_270', 'CC_271', 'CC_272', 'CC_274', 'CC_275', 'CC_276', 'CC_278', 'CC_281', 'CC_283', 'CC_284', 'CC_289', 'CC_291', 'CC_294', 'CC_300', 'CC_306', 'CC_308', 'CC_310', 'CC_311', 'CC_312', 'CC_314', 'CC_319', 'CC_322', 'CC_329', 'CC_330', 'CC_332', 'CC_336', 'CC_342', 'CC_349', 'CC_351', 'CC_352', 'CC_359', 'CC_361', 'CC_366', 'CC_367', 'CC_368', 'CC_370', 'CC_371', 'CC_372', 'CC_378', 'CC_381', 'CC_384', 'CC_386', 'CC_387', 'CC_391', 'CC_394', 'CC_395', 'CC_396', 'CC_397', 'CC_398', 'CC_400', 'CC_401', 'CC_402', 'CC_403', 'CC_404', 'CC_405', 'CC_409', 'CC_410', 'CC_411', 'CC_418', 'CC_420', 'CC_422', 'CC_423', 'CC_432', 'CC_433', 'CC_435', 'CC_436', 'CC_440', 'CC_445', 'CC_446', 'CC_448', 'CC_449', 'CC_450', 'CC_451', 'CC_453', 'CC_454', 'CC_455', 'CC_457', 'CC_458', 'CC_462', 'CC_463', 'CC_467', 'CC_470', 'CC_473', 'CC_474', 'CC_477', 'CC_481', 'CC_482', 'CC_483', 'CC_484', 'CC_487', 'CC_488', 'CC_494', 'CC_496', 'CC_499', 'CC_500', 'CC_501', 'CC_506', 'CC_507', 'CC_509', 'CC_510', 'CC_511', 'CC_512', 'CC_515', 'CC_516', 'CC_518', 'CC_519')
ORDER BY course_id;
