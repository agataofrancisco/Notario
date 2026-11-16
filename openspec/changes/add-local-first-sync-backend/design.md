# Design

## Context

See [proposal.md](proposal.md). The current Flutter client already has SQLite, local notifications, Google Sign-In, and direct Calendar/Tasks calls. Firestore is unsuitable as a mandatory path because this project returns a billing-required error. Google Calendar access is user-owned OAuth data and does not require a shared service account or a central Calendar backend.

## Goals / Non-Goals

**Goals:**

- Let any person sign in with Google and authorize their own Calendar/Tasks.
- Keep Calendar import and local notifications available with no backend and no Firestore billing dependency.
- Define a small optional Go backend for progress-only backup and cross-device progress recovery.
- Keep the backend replaceable and inexpensive to self-host.

**Non-Goals:**

- Rebuild Google Calendar/Tasks in the backend.
- Store Google refresh tokens, task records, or impersonate a person's Calendar server-side.
- Add teams, sharing, payments, realtime collaboration, or push notifications in the first backend release.
- Migrate existing Firestore data automatically.

## Decisions

### 1. Direct Google OAuth remains in the mobile client

The Flutter app signs a person in using native Google Sign-In and calls Calendar/Tasks with that person's short-lived access token. This supports many users: every person has an independent Google subject ID and consent grant. The Google Cloud OAuth consent screen must be configured as **External** before public release, with Android and iOS OAuth client IDs in the same project.

The app requests read scopes for import and asks for write scopes only when the person enables two-way Calendar/Tasks sync. This follows Google's least-privilege guidance.

**Alternatives considered:**

- Google Apps Script: suitable for one account but adds a web-app backend, deployment identity, quotas, and a proxy API; it is not a simpler multi-user mobile architecture.
- Server-side Google refresh tokens: increases secret storage, token-revocation, and breach scope with no benefit for current offline-first behavior.

### 2. SQLite is authoritative; cloud receives progress events only

The client commits every change and schedules reminders locally first. On completion it produces a progress event containing an operation ID, device ID, event timestamp, actual elapsed minutes, and optional aggregate counters. Network workers upload pending progress events later and obtain a cursor of remote progress events.

Progress events are immutable and deduplicated by operation ID. The app calculates task details locally; the backend calculates only user aggregates from the event set. This avoids task conflicts and a complex CRDT.

### 3. Minimal backend: Go API plus PostgreSQL

Implement one small Go HTTP service (standard `net/http` plus a small router) deployed as a container. It verifies Google ID tokens against Google's public keys and uses `sub` as `user_id`. PostgreSQL stores progress events and aggregate counters; it never stores Google access/refresh tokens or task payloads.

Required endpoints:

| Endpoint | Purpose |
| --- | --- |
| `POST /v1/progress/push` | Idempotently accept a batch of progress events. |
| `GET /v1/progress/pull?cursor=…` | Return later progress events, aggregate totals, and next cursor. |
| `DELETE /v1/account/data` | Delete the caller's backup data. |
| `GET /healthz` | Unauthenticated service health. |

All sync endpoints use `Authorization: Bearer <Google ID token>`, validate issuer, audience, expiry, and signature, and enforce request/body size limits. The first release has no admin endpoint and no service-account credential.

Core tables:

| Table | Key fields |
| --- | --- |
| `progress_events` | `operation_id` (unique), `user_id`, `device_id`, `completed_at`, `actual_minutes`, `kind`, `created_at` |
| `progress_aggregates` | `user_id`, `completed_count`, `actual_minutes_total`, `last_completed_at`, `version` |
| `sync_cursors` | `user_id`, monotonic `cursor` |

The request schema has no task field and rejects unknown task-content fields. The backend can retain progress totals but cannot receive titles, notes, planned schedules, Google IDs, or activity states.

**Alternatives considered:**

- Firestore: rejected from the required path because billing configuration currently rejects writes.
- Apps Script datastore: rejected because it does not provide a robust multi-user synchronization database, token verification boundary, or conflict protocol.
- Full GraphQL/realtime backend: rejected as unnecessary for batched personal productivity sync.

### 4. Google Calendar is a separate replica

Google IDs and Calendar sync status stay in the local entity. The client imports a bounded offline planning window, schedules local reminders, and later sends explicitly enabled local updates to Google. Failure of Google, backup, or Firestore adapters updates only that adapter's pending state; it never rolls back SQLite.

All civil-day calculations and displayed task timestamps use `Africa/Luanda`; persisted instants and API ranges use UTC ISO-8601. Calendar event `timeZone` is sent as `Africa/Luanda` with the matching UTC instant.

## Risks / Trade-offs

- [OAuth sensitive scopes require consent-screen verification before broad public use] → Start in testing with named test users; prepare privacy policy, terms, verified domains, and scope justification before publishing.
- [A self-hosted server still needs a host] → Keep it optional; deploy a single container and managed Postgres only when cross-device backup is needed. Local + Google continues with no server.
- [Progress-only backup cannot recreate tasks on a new device] → Tasks remain on their originating device; add encrypted task backup only in a separately approved future change.
- [Conflict UX is more work than last-write-wins] → Ship deterministic resolution with retained conflict metadata; add a conflict screen only after telemetry confirms demand.
- [Operating-system notification limits] → Persist all activities locally; schedule/reconcile future reminders within platform limits and retry at app launch.

## Migration Plan

1. Release a client switch that disables Firestore as a required adapter and exposes direct Google connection state.
2. Configure an External OAuth consent screen, Android/iOS clients, required Calendar/Tasks APIs, and test users; no billing account is required for standard Calendar use.
3. Release SQLite progress-event fields and adapter status fields without enabling backend sync.
4. Deploy the backend in a non-production environment, run token-verification and idempotency tests, then enable it for opted-in testers.
5. Enable production backup only after deletion/export behavior, rate limits, privacy policy, and OAuth publication are validated.

Rollback: disable the backend base URL/feature flag. The application remains usable entirely from SQLite and direct Google synchronization.

## Open Questions

- Which hosting provider and region meet the owner's cost and data-residency preferences? This does not affect the HTTP contract.
