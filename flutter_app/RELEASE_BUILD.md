# Golf Windy Release Build

현재 배포 빌드는 구독 없이 모든 스코어 기능을 무료로 제공합니다.

## 준비 값

- `API_BASE_URL`
- `FREE_PRO_FEATURES`

예시:

```json
{
  "API_BASE_URL": "https://weather-app-production-7ab9.up.railway.app",
  "FREE_PRO_FEATURES": "true"
}
```

## iOS

```bash
./scripts/build_release_ios.sh
```

## Android

```bash
./scripts/build_release_android.sh
```
