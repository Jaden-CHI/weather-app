# Fishing Windy server condition alerts

## Deployment status

Implementation and isolated database tests are local. This document is not evidence of production activation or actual device delivery. No paid entitlement is required. Golf notification tables, Firebase configuration and collection interval remain unchanged.

## Configuration

1. Firebase Console: select **fishing-windy-moonyth**, not Golf Windy. Confirm Authentication is enabled for the login methods offered by the app.
2. Project settings > Service accounts: configure a dedicated server service account with Firebase Authentication user-read permissions and FCM send permissions. Store its JSON privately in Railway, never in Git, Flutter assets or chat.
3. Set these in BOTH the API and worker services:
   - `FISHING_FIREBASE_PROJECT_ID=fishing-windy-moonyth`
   - `FISHING_FIREBASE_SERVICE_ACCOUNT_JSON=<private service account JSON>`
   - `FISHING_TRIP_PUSH_ENABLED=false` until the app and server are ready.
   Existing `FIREBASE_PROJECT_ID` / `FIREBASE_SERVICE_ACCOUNT_JSON` are for the previous Golf sender and must not be changed for this feature.
4. Ensure Firebase Cloud Messaging API (HTTP v1) is enabled. In Project settings > Cloud Messaging > the iOS app `com.moonyth.fishingWindy`, configure the Apple APNs authentication key, key ID and Apple team. This is not the App Store Connect upload key.
5. In Apple Developer/Xcode enable Push Notifications for the app identifier and refresh provisioning profiles. Debug uses development APS, Release/Profile production. The app uses visible notification messages, not background location or exact alarms.
6. Deploy backend API and worker from this worktree. Both use existing PostgreSQL; schema startup creates three isolated `fishing_*` tables. Existing data is not migrated or deleted. Worker also needs the existing KMA key and Redis URL. Do not replace those keys.
7. Enable `FISHING_TRIP_PUSH_ENABLED=true` on API and worker after configuration. The dedicated task checks roughly every 30 minutes independently of Golf collection, without changing `WORKER_INTERVAL_MINUTES`.
8. Install the new app build. Sign in, open My trip plans, opt in to server alerts, allow OS notifications and check that registration succeeds. Merely seeing a switch ON means desired state, not acknowledged server registration. Check its status text.

## Real-device acceptance gate (still required)

- Use one's own test account/device, a real port/time within 48 hours, and deliberately chosen personal criteria. Do not change production forecasts to force a notification.
- Confirm the API registration and worker `checked_at` advance, a state-change event exists and FCM reports sent. `sent` means FCM accepted, NOT that the device displayed it.
- Background the app, wait for a check and observe the OS notification. Tap it; the plans screen must open. Also test a normal terminated launch, token rotation and permission denial on iOS and Android.
- Edit/off/delete a plan and confirm server snapshot acknowledgement. No additional message may be queued for the removed revision. Messages already accepted by FCM cannot be recalled; TTL is capped to 30 minutes and remaining trip time.
- Test network failure: local edits are retained, but older server conditions may remain until retry. Logout is blocked until this device's registration is removed. Account deletion removes registrations; deleted/disabled Firebase users are also removed by the worker.
- Test account isolation and a second installation. Plan origin is local; server copies are not a cross-device backup/restore feature.
- Confirm paid UI remains disabled. Update the published privacy notice and store data disclosures before release: account ID, FCM device token, intended port/time and personal limits are transmitted only after server-alert opt-in.

## Reliability and limits

- KMA only: inclusive wind m/s and wave-height m limits; known breach overrides incomplete hours, missing/stale values never become zero or favorable.
- Check the shared KMA daily allowance before activation. Without a reusable fresh cache, 30-minute polling adds up to 48 requests per active port per day (15 ports: 720), not per user. Add existing Golf/marine requests when checking the quota; do not reduce the shared collection interval.
- Fetch age <=3 hours, issue age <=12 hours, no timestamp >5 minutes ahead. Plans >48 hours away wait. Finished plans do not notify.
- PostgreSQL lock prevents overlapping workers. State changes and durable pending events are committed before delivery. Transient FCM failures retry on a later check. New state/revision supersedes old pending events.
- Delivery is at-least-once, not exactly-once: crash after FCM accepts but before DB commit can repeat. Stable per-plan Android tag and APNs collapse ID reduce duplicate presentation.
- Device and plan row locks serialize edits/cancellation with dispatch. FCM tokens invalidated by uninstall disable that installation; authentication outages defer checks without deleting valid users.
- At most 5 installations/account, 30 active alert plans/installation. Devices expire 32 days after last successful sync; reopening/syncing renews the lease. Ended plans and events are purged after 30 days on the next running worker cycle. Removing a device/plan cascades its events immediately.
- Never use these personal conditions as departure authorization, distress monitoring or guaranteed safety.

## Verification command

Use an isolated PostgreSQL database named `fishing_trip_test` only. Set `TEST_TRIP_DATABASE_URL` to its asyncpg URL and run:

```sh
PYTHONPATH=backend /tmp/weather-port-venv/bin/python -m unittest discover -s backend/tests -v
```

Tests override authentication only inside their FastAPI instance and mock FCM delivery. Production never trusts client-provided user IDs. Firebase ID tokens are project-verified with revocation checks.

## Rollback

Set `FISHING_TRIP_PUSH_ENABLED=false` on the worker to stop checks/sends, and on the API to reject new snapshots. Authenticated status/delete remain available while credentials are valid. No destructive schema rollback is needed. Local plans and foreground checks continue; users should turn off server mode to resume local notifications.

References:
- https://firebase.google.com/docs/cloud-messaging/flutter/get-started
- https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages
- https://firebase.google.com/docs/auth/admin/verify-id-tokens
