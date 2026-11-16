# Proposal

## Why

Notário must support several people signing in with their own Google accounts without making task use depend on Cloud Firestore billing. The app already has SQLite as its durable source of truth; the missing piece is a small, explicit backend boundary for optional cross-device backup and secure sync.

## What Changes

- Keep SQLite and local notifications as the primary offline experience; no feature may require a backend request to create, start, complete, or view an activity.
- Define Google Sign-In as multi-user authentication: each person consents to access only their own Calendar and Tasks data.
- Introduce an optional, billing-free self-hostable Go backend for per-user progress backup and cross-device progress recovery; task records remain device-local.
- Remove Cloud Firestore from the required runtime sync path; it may remain an opt-in adapter, but its billing/configuration failure must not block local or Google synchronization.
- Define a small HTTPS API, authentication verification, conflict rules, retention, and operational limits for the backend.

## Capabilities

### New Capabilities

- `google-account-connection`: Identifies users through Google Sign-In and obtains consented access to each user's own Google Calendar/Tasks data.
- `local-first-sync-backend`: Provides optional authenticated progress backup and cross-device progress synchronization without making the mobile app network-dependent or uploading tasks.

### Modified Capabilities

- None.

## Impact

- Flutter auth, local task repository, and synchronization service.
- New self-hosted Go backend/API and deployment documentation; no Firestore dependency in the critical path and no cloud task storage.
- Google Cloud OAuth consent screen, Android/iOS OAuth clients, Calendar API, and Google Tasks API configuration.
