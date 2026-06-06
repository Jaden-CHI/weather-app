# Railway Deployment

Golf Windy backend is a FastAPI API with a background worker, PostgreSQL, and Redis.

## Services

Create one Railway project with these services:

1. `api`
   - Source: GitHub repository
   - Root directory: `backend`
   - Dockerfile: `backend/Dockerfile` is detected automatically
   - Start command: leave empty, Dockerfile `CMD` is used
   - Public networking: enabled
   - Healthcheck path: `/health`

2. `worker`
   - Source: same GitHub repository
   - Root directory: `backend`
   - Start command override:

   ```bash
   python -m workers.scheduler
   ```

   - Public networking: disabled

3. `Postgres`
   - Add via Railway PostgreSQL template

4. `Redis`
   - Add via Railway Redis template

## Variables

Set these variables on both `api` and `worker` services:

```bash
DATABASE_URL=${{Postgres.DATABASE_URL}}
REDIS_URL=${{Redis.REDIS_URL}}
USE_MOCK_DATA=true
WEATHER_CACHE_TTL=10800
WORKER_INTERVAL_MINUTES=60
CORS_ORIGINS=*
```

Optional, when real API keys are ready:

```bash
KMA_API_KEY=...
KHOA_API_KEY=...
ANTHROPIC_API_KEY=...
USE_MOCK_DATA=false
```

Railway commonly provides `DATABASE_URL` as `postgresql://...`; the backend normalizes it to `postgresql+asyncpg://...` automatically.

## First Deploy Check

After deployment, open:

```bash
https://YOUR-API-DOMAIN.up.railway.app/health
```

Expected:

```json
{"status":"ok","service":"weather-api"}
```

Then verify course search:

```bash
https://YOUR-API-DOMAIN.up.railway.app/api/v1/golf/courses/search?q=남서울
```

After the worker runs once, verify weather:

```bash
https://YOUR-API-DOMAIN.up.railway.app/api/v1/golf/courses/CC_042/weather?dday=1
```

## Flutter Release Rebuild

Use the Railway API domain as `API_BASE_URL`:

```bash
cd flutter_app
flutter build appbundle --release --dart-define=API_BASE_URL=https://YOUR-API-DOMAIN.up.railway.app
flutter build ipa --release --export-method app-store --dart-define=API_BASE_URL=https://YOUR-API-DOMAIN.up.railway.app
```
