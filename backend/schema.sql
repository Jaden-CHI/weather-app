-- Golf Windy database schema.
-- This is intentionally self-contained so hosted Postgres instances can be
-- initialized by the API/worker without relying on docker-compose mounts.

CREATE TABLE IF NOT EXISTS golf_courses (
    course_id       VARCHAR(20) PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    name_short      VARCHAR(50),
    region          VARCHAR(20) NOT NULL,
    address         TEXT,
    lat             NUMERIC(9,6) NOT NULL,
    lon             NUMERIC(9,6) NOT NULL,
    grid_x          INT NOT NULL,
    grid_y          INT NOT NULL,
    holes           SMALLINT DEFAULT 18,
    phone           VARCHAR(20),
    website         TEXT,
    public_data_id  VARCHAR(50),
    golfzon_id      VARCHAR(30),
    golfzon_url     TEXT,
    golfzon_linked  BOOLEAN DEFAULT FALSE,
    data_source     VARCHAR(20) DEFAULT 'MANUAL',
    verified_at     TIMESTAMP,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS course_cancellation_policies (
    policy_id               SERIAL PRIMARY KEY,
    course_id               VARCHAR(20) REFERENCES golf_courses(course_id) ON DELETE CASCADE,
    season                  VARCHAR(10) DEFAULT 'ALL',
    free_cancel_hours       INT,
    free_cancel_desc        TEXT,
    same_day_penalty        TEXT,
    noshow_penalty          TEXT,
    rain_cancel_available   BOOLEAN DEFAULT FALSE,
    rain_cancel_condition   TEXT,
    rain_refund_rule        TEXT,
    source_url              TEXT,
    verified_at             TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT NOW(),
    UNIQUE (course_id)
);

CREATE TABLE IF NOT EXISTS fishing_spots (
    spot_id         VARCHAR(20) PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    name_short      VARCHAR(50),
    region          VARCHAR(20) NOT NULL,
    sea_type        VARCHAR(10) NOT NULL,
    address         TEXT,
    lat             NUMERIC(9,6) NOT NULL,
    lon             NUMERIC(9,6) NOT NULL,
    grid_x          INT NOT NULL,
    grid_y          INT NOT NULL,
    khoa_obs_code   VARCHAR(10),
    buoy_id         VARCHAR(10),
    main_fish       TEXT[],
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS weather_cache_log (
    log_id          SERIAL PRIMARY KEY,
    target_type     VARCHAR(10) NOT NULL,
    target_id       VARCHAR(20) NOT NULL,
    grid_x          INT,
    grid_y          INT,
    collected_at    TIMESTAMP NOT NULL,
    source          VARCHAR(20) NOT NULL,
    success         BOOLEAN NOT NULL,
    error_msg       TEXT
);

CREATE TABLE IF NOT EXISTS user_devices (
    device_id       SERIAL PRIMARY KEY,
    user_token      VARCHAR(100) NOT NULL UNIQUE,
    fcm_token       TEXT NOT NULL,
    platform        VARCHAR(10) NOT NULL,
    app_version     VARCHAR(20),
    user_tier       VARCHAR(10) NOT NULL DEFAULT 'FREE',
    registered_at   TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_subscriptions (
    sub_id          SERIAL PRIMARY KEY,
    user_token      VARCHAR(100) NOT NULL,
    activity_type   VARCHAR(10) NOT NULL,
    target_id       VARCHAR(20) NOT NULL,
    event_date      DATE NOT NULL,
    event_title     VARCHAR(200),
    rain_threshold  INT DEFAULT 60,
    wind_threshold  NUMERIC DEFAULT 10.0,
    last_status     VARCHAR(10),
    last_notified   TIMESTAMP,
    active          BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notification_log (
    log_id          SERIAL PRIMARY KEY,
    user_token      VARCHAR(100) NOT NULL,
    sub_id          INT REFERENCES user_subscriptions(sub_id),
    title           VARCHAR(200) NOT NULL,
    body            TEXT NOT NULL,
    status          VARCHAR(10) NOT NULL,
    fcm_result      VARCHAR(20),
    sent_at         TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cache_log_target ON weather_cache_log(target_type, target_id, collected_at DESC);
CREATE INDEX IF NOT EXISTS idx_devices_token ON user_devices(user_token);
CREATE INDEX IF NOT EXISTS idx_subs_user ON user_subscriptions(user_token, active);
CREATE INDEX IF NOT EXISTS idx_subs_date ON user_subscriptions(event_date, active);
CREATE INDEX IF NOT EXISTS idx_notif_user ON notification_log(user_token, sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_golf_region ON golf_courses(region);
CREATE INDEX IF NOT EXISTS idx_golf_grid ON golf_courses(grid_x, grid_y);
CREATE INDEX IF NOT EXISTS idx_golf_golfzon ON golf_courses(golfzon_id) WHERE golfzon_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_golf_linked ON golf_courses(golfzon_linked) WHERE golfzon_linked = TRUE;
CREATE INDEX IF NOT EXISTS idx_fishing_sea ON fishing_spots(sea_type);
CREATE INDEX IF NOT EXISTS idx_fishing_grid ON fishing_spots(grid_x, grid_y);
CREATE TABLE IF NOT EXISTS fishing_push_devices (
    uid VARCHAR(128) NOT NULL,
    installation_id UUID NOT NULL,
    fcm_token TEXT NOT NULL UNIQUE,
    platform VARCHAR(10) NOT NULL,
    revision BIGINT NOT NULL,
    payload_hash TEXT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (uid, installation_id)
);

CREATE TABLE IF NOT EXISTS fishing_trip_plans (
    uid VARCHAR(128) NOT NULL,
    installation_id UUID NOT NULL,
    plan_id VARCHAR(80) NOT NULL,
    payload JSONB NOT NULL,
    revision BIGINT NOT NULL,
    last_state VARCHAR(20),
    checked_at TIMESTAMPTZ,
    PRIMARY KEY (uid, installation_id, plan_id),
    FOREIGN KEY (uid, installation_id) REFERENCES fishing_push_devices ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS fishing_trip_events (
    event_id UUID PRIMARY KEY,
    uid VARCHAR(128) NOT NULL,
    installation_id UUID NOT NULL,
    plan_id VARCHAR(80) NOT NULL,
    revision BIGINT NOT NULL,
    state VARCHAR(20) NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    delivery VARCHAR(20) NOT NULL DEFAULT 'pending',
    attempts INTEGER NOT NULL DEFAULT 0,
    next_attempt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (uid, installation_id, plan_id) REFERENCES fishing_trip_plans ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS fishing_trip_pending ON fishing_trip_events (next_attempt) WHERE delivery='pending';
