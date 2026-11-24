# Marine forecast integration

## Data boundaries

- KMA `VilageFcstInfoService_2.0/getVilageFcst` supplies port-grid forecasts, not observations or offshore-vessel conditions.
- Compute nx/ny from seed latitude/longitude. All 15 pre-existing seed grid pairs differed from the coordinate-derived grids; those stored grid fields are not used by this collector.
- Parse WSD (m/s), VEC (degrees), WAV (m), TMP (C), POP (%). Invalid, negative sentinel and missing wind/wave values are omitted, never replaced with zero.
- Keep KST forecast timestamps and issuance metadata. A future hour is not the current hour. Return at most the upcoming 24 hours.
- Cache upstream rows by grid and issuance for six hours; select the valid time window on every collection. Quota errors suppress new marine forecast requests until the next KST day (daily limit) or 15 minutes (unclassified HTTP 429). Already cached grids remain usable.
- Weather, warning and tide requests fail independently. A missing source is represented explicitly; failed-source values are not copied into a freshly timestamped payload.

## Safety limitations

The warning-message endpoint returns bulletins, not a verified active-warning list matched to each port. Its output is `unverified`, including when it returns no messages. Missing or stale wind/wave values and unverified warnings cannot produce a positive departure decision. Known severe current-hour forecasts can still produce a cautionary RED result. Marine advice is deterministic; an LLM cannot override missing safety inputs.

Japan JMA remains an official broad-area link in the Flutter client, not a numerical Korean-port model feed. No paid provider was enabled.

## Verification on 2026-11-24

- Backend regression suite: 85 tests passed before deployment (one dependency deprecation warning).
- Existing Railway worker probe for Tongyeong grid 87,68 returned HTTP 429 / LIMITED_NUMBER_OF_SERVICE_REQUESTS_EXCEEDS_ERROR. Successful production numerical values cannot be verified until the upstream daily quota becomes available.
- Worker interval observed previously: one minute. Changing this setting also affects the golf collection workflow, so it is a separate operator decision.

Reference: https://apihub.kma.go.kr/apiList.do?seqApi=10
