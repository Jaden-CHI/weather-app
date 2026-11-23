# KHOA Tide Mapping Audit - 2026-11-23

Source: https://www.data.go.kr/data/15156018/openapi.do
Official guide: `오픈API 활용가이드_조석예보(고, 저조)_261106.hwpx`, station code table.
Live verification: production worker, 2026-11-23 KST, new HTTPS API.
No credentials are recorded in this document.

The old seed contained geographically incorrect station codes. An HTTP success
was not evidence that the forecast belonged to the requested port.

## Audited Regional Reference Stations

| Spot | Official code | Returned station name | Returned latitude | Returned longitude | Tide records |
| --- | --- | --- | --- | --- | --- |
| FS_001 | DT_0014 | 통영 | 34.82777 | 128.43472 | 4 |
| FS_002 | SO_0552 | 고현항 | 34.90194 | 128.62222 | 4 |
| FS_003 | DT_0016 | 여수 | 34.74722 | 127.76555 | 4 |
| FS_004 | DT_0005 | 부산 | 35.09638 | 129.03527 | 4 |
| FS_005 | DT_0065 | 덕적도 | 37.22633 | 126.15655 | 4 |
| FS_007 | DT_0027 | 완도 | 34.31555 | 126.75972 | 4 |
| FS_008 | DT_0022 | 성산포 | 33.47472 | 126.92777 | 4 |
| FS_009 | DT_0023 | 모슬포 | 33.21444 | 126.25111 | 4 |
| FS_010 | DT_0013 | 울릉도 | 37.49138 | 130.91361 | 4 |
| FS_011 | DT_0012 | 속초 | 38.20722 | 128.59416 | 4 |
| FS_013 | SO_1267 | 구룡포항 | 35.99 | 129.55555 | 4 |
| FS_014 | DT_0007 | 목포 | 34.77972 | 126.37555 | 4 |

These are regional reference forecasts, not measurements at every fishing spot.
Name/code and regional location were checked; hydrodynamic equivalence and
individual fishing spot coordinates have not been independently surveyed.
The API returns `tide_station` with the station name/code and
`relation: regional_reference`. Clients should label this reference explicitly.

## Withheld Mappings

- FS_006 (만리포): old DT_0021 is 추자도. Verify the port coordinates and an
  appropriate forecast point before enabling a replacement.
- FS_012 (주문진): old DT_0040 is not a supported code in this guide. Do not
  silently substitute another east-coast station.
- FS_015 (선유도): old DT_0034 is not supported in this guide. A local forecast
  point must be verified; do not substitute mainland 군산 just because of the city name.

These rows have null station codes and return `tide_status: mapping_unverified`,
empty tides, and no calculated golden time. This is not a claim of zero tide.

## Deployment and Cache Safety

- Startup sync updates only `khoa_obs_code` for the 15 seed IDs in Postgres.
- Existing cached tides without the new mapping version are excluded by the API.
- New collection validates returned station names against the audited mapping.
- Failure does not overwrite cache with a false fresh forecast.
- Scheduled collection and weather-warning interpretation require separate checks;
  tide success is not evidence of safe departure or working weather alerts.
