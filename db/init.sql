-- ══════════════════════════════════════════════
--  켜자마자 날씨 — 데이터베이스 스키마
-- ══════════════════════════════════════════════

-- ── 골프장 마스터 ─────────────────────────────
CREATE TABLE golf_courses (
    course_id       VARCHAR(20) PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    name_short      VARCHAR(50),                -- 잠금화면 표시용 짧은 이름
    region          VARCHAR(20) NOT NULL,        -- 시/도
    address         TEXT,
    lat             NUMERIC(9,6) NOT NULL,
    lon             NUMERIC(9,6) NOT NULL,
    grid_x          INT NOT NULL,               -- 기상청 격자 X
    grid_y          INT NOT NULL,               -- 기상청 격자 Y
    holes           SMALLINT DEFAULT 18,
    phone           VARCHAR(20),
    website         TEXT,
    -- ── 공공데이터 출처 ──────────────────────────
    public_data_id  VARCHAR(50),                -- 문화체육관광부 체육시설업 고유번호
    -- ── 골프존 제휴 (향후 API 연동 대비) ──────────
    golfzon_id      VARCHAR(30),                -- 골프존 코스 ID (제휴 후 채움)
    golfzon_url     TEXT,                       -- 골프존 예약 페이지 URL
    golfzon_linked  BOOLEAN DEFAULT FALSE,      -- 골프존 예약 연동 활성화 여부
    -- ── 데이터 관리 ──────────────────────────────
    data_source     VARCHAR(20) DEFAULT 'MANUAL', -- MANUAL / PUBLIC_DATA / GOLFZON
    verified_at     TIMESTAMP,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- ── 골프장 취소 정책 ──────────────────────────
CREATE TABLE course_cancellation_policies (
    policy_id               SERIAL PRIMARY KEY,
    course_id               VARCHAR(20) REFERENCES golf_courses(course_id) ON DELETE CASCADE,
    season                  VARCHAR(10) DEFAULT 'ALL',   -- ALL / PEAK / OFF
    -- 무료 취소 기한
    free_cancel_hours       INT,          -- 몇 시간 전까지 무료 취소 가능
    free_cancel_desc        TEXT,         -- 예: "라운딩 전날 18:00까지"
    -- 당일/노쇼 페널티
    same_day_penalty        TEXT,         -- 예: "그린피 100% 청구"
    noshow_penalty          TEXT,         -- 예: "3개월 예약 정지"
    -- 우천 특별 정책
    rain_cancel_available   BOOLEAN DEFAULT FALSE,
    rain_cancel_condition   TEXT,         -- 예: "당일 오전 6시까지 기상청 강우 확인 후 취소 가능"
    rain_refund_rule        TEXT,         -- 예: "9홀 미만 완료 시 50% 환불"
    -- 메타
    source_url              TEXT,
    verified_at             TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT NOW(),
    UNIQUE (course_id)
);

-- ── 낚시 출항지 마스터 ────────────────────────
CREATE TABLE fishing_spots (
    spot_id         VARCHAR(20) PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    name_short      VARCHAR(50),
    region          VARCHAR(20) NOT NULL,
    sea_type        VARCHAR(10) NOT NULL,        -- WEST(서해) / SOUTH(남해) / EAST(동해) / JEJU
    address         TEXT,
    lat             NUMERIC(9,6) NOT NULL,
    lon             NUMERIC(9,6) NOT NULL,
    grid_x          INT NOT NULL,               -- 기상청 격자 X
    grid_y          INT NOT NULL,               -- 기상청 격자 Y
    -- 해양조사원 관측소 코드 (조석 예보용)
    khoa_obs_code   VARCHAR(10),
    -- 해양기상 부이 코드
    buoy_id         VARCHAR(10),
    -- 주요 어종
    main_fish       TEXT[],
    created_at      TIMESTAMP DEFAULT NOW()
);

-- ── 날씨 캐시 메타 (Redis 보조, 수집 이력용) ──
CREATE TABLE weather_cache_log (
    log_id          SERIAL PRIMARY KEY,
    target_type     VARCHAR(10) NOT NULL,   -- GOLF / MARINE
    target_id       VARCHAR(20) NOT NULL,
    grid_x          INT,
    grid_y          INT,
    collected_at    TIMESTAMP NOT NULL,
    source          VARCHAR(20) NOT NULL,   -- KMA / OPEN_METEO / KHOA / MOCK
    success         BOOLEAN NOT NULL,
    error_msg       TEXT
);

CREATE INDEX idx_cache_log_target ON weather_cache_log(target_type, target_id, collected_at DESC);

-- ── 사용자 디바이스 (FCM 토큰) ───────────────────
CREATE TABLE user_devices (
    device_id       SERIAL PRIMARY KEY,
    user_token      VARCHAR(100) NOT NULL UNIQUE, -- 앱에서 생성한 익명 UUID
    fcm_token       TEXT NOT NULL,
    platform        VARCHAR(10) NOT NULL,          -- IOS / ANDROID
    app_version     VARCHAR(20),
    user_tier       VARCHAR(10) NOT NULL DEFAULT 'FREE', -- FREE / PRO (미래 유료플랜 대비)
    registered_at   TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_devices_token ON user_devices(user_token);

-- ── 사용자 날씨 구독 (골프 일정 모니터링 등록) ───
CREATE TABLE user_subscriptions (
    sub_id          SERIAL PRIMARY KEY,
    user_token      VARCHAR(100) NOT NULL,
    activity_type   VARCHAR(10) NOT NULL,   -- GOLF / MARINE
    target_id       VARCHAR(20) NOT NULL,   -- course_id or spot_id
    event_date      DATE NOT NULL,          -- 라운딩 날짜
    event_title     VARCHAR(200),           -- 캘린더 일정 제목
    -- 알림 임계값 (사용자 설정 반영)
    rain_threshold  INT DEFAULT 60,         -- 강수확률 X% 이상이면 알림
    wind_threshold  NUMERIC DEFAULT 10.0,   -- 풍속 Xm/s 이상이면 알림
    -- 상태 추적
    last_status     VARCHAR(10),            -- 직전 알림 상태 (GREEN/YELLOW/RED)
    last_notified   TIMESTAMP,
    active          BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_subs_user ON user_subscriptions(user_token, active);
CREATE INDEX idx_subs_date ON user_subscriptions(event_date, active);

-- ── 알림 발송 이력 ────────────────────────────────
CREATE TABLE notification_log (
    log_id          SERIAL PRIMARY KEY,
    user_token      VARCHAR(100) NOT NULL,
    sub_id          INT REFERENCES user_subscriptions(sub_id),
    title           VARCHAR(200) NOT NULL,
    body            TEXT NOT NULL,
    status          VARCHAR(10) NOT NULL,   -- GREEN / YELLOW / RED
    fcm_result      VARCHAR(20),            -- SUCCESS / FAILED / INVALID_TOKEN
    sent_at         TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_notif_user ON notification_log(user_token, sent_at DESC);

-- ── 인덱스 ────────────────────────────────────
CREATE INDEX idx_golf_region ON golf_courses(region);
CREATE INDEX idx_golf_grid ON golf_courses(grid_x, grid_y);
CREATE INDEX idx_golf_golfzon ON golf_courses(golfzon_id) WHERE golfzon_id IS NOT NULL;
CREATE INDEX idx_golf_linked ON golf_courses(golfzon_linked) WHERE golfzon_linked = TRUE;
CREATE INDEX idx_fishing_sea ON fishing_spots(sea_type);
CREATE INDEX idx_fishing_grid ON fishing_spots(grid_x, grid_y);
