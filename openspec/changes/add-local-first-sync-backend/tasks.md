# Tasks

## 1. Google identity and client configuration

- [ ] 1.1 Configure the Google OAuth consent screen as External, register Android and iOS client IDs, add test users, and verify two distinct Google accounts receive distinct app identities.
- [ ] 1.2 Split Calendar/Tasks consent into read-only import and explicit write-sync grants; verify declining either grant leaves SQLite task creation, focus mode, and reminders functional.
- [ ] 1.3 Remove Firestore from the required synchronization path behind a feature flag and verify a rejected Firestore request cannot prevent local or Google synchronization.
- [ ] 1.4 Document OAuth production prerequisites, requested scopes, privacy-policy requirements, and test-user setup; verify every setup link and step against the Google console.

## 2. Local operation log

- [ ] 2.1 Add durable device ID, operation ID, progress-event queue, and adapter statuses to SQLite; verify an offline completion survives app restart without exporting task content.
- [ ] 2.2 Implement idempotent progress-event creation for completions and verify a retried event does not duplicate total minutes or completion count.
- [ ] 2.3 Add deterministic progress-event deduplication and aggregate reconciliation; verify distinct completions from two seeded device logs are both counted.
- [ ] 2.4 Reconcile upcoming local reminders from SQLite at boot within platform limits; verify reminders for imported Google activities persist after an offline relaunch.

## 3. Minimal Go progress backend

- [ ] 3.1 Scaffold the Go HTTP service, PostgreSQL schema, container configuration, and health endpoint; verify the service starts locally and `GET /healthz` succeeds.
- [ ] 3.2 Implement Google ID-token verification for issuer, audience, expiry, and signature; verify missing, expired, wrong-audience, and valid tokens return the expected status codes.
- [x] 3.3 Implement `POST /v1/progress/push` with per-user authorization, request limits, operation-ID idempotency, and a schema that rejects task content and Google identifiers; verify repeat push produces no duplicate progress event.
- [x] 3.4 Implement cursor-based `GET /v1/progress/pull` with strict per-user filtering and aggregate totals; verify one account cannot retrieve another account's records.
- [x] 3.5 Implement authenticated `DELETE /v1/account/data`; verify deletion removes only the caller's cloud backup and does not alter an emulated device-local database.
- [ ] 3.6 Add backend API, privacy, retention, and self-host deployment documentation; verify a clean environment can run the documented local setup.

## 4. Flutter backup adapter

- [ ] 4.1 Implement authenticated push/pull client calls using fresh Google ID tokens and bounded retry/backoff; verify airplane-mode operations remain queued and synchronize after connectivity returns.
- [ ] 4.2 Send progress-only backup requests and verify fixtures contain no Google access token, refresh token, title, note, schedule, Google ID, or task payload.
- [ ] 4.3 Add visible sync status and recoverable error messaging that distinguishes local success, Google pending, and backup pending; verify Firestore billing failure remains non-blocking.
- [ ] 4.4 Add integration tests for two Google identities and two device progress logs, covering offline completion, deduplication, deletion, and no cross-user data access.

## 5. Release validation

- [ ] 5.1 Verify Android and iOS Google Sign-In and Calendar import using two real test accounts, including `Africa/Luanda` timestamps and local focus completion.
- [ ] 5.2 Run Flutter analysis/tests and backend unit/integration tests in CI; verify all pass before enabling the backup endpoint for testers.
- [ ] 5.3 Conduct a security review of token handling, TLS, secret configuration, database access, log redaction, rate limits, and account-deletion behavior; record remediation or approval.

## Workflow follow-up

- Review the proposal, design, and API contract before implementation.
- Run `/opsx:apply` or ask to implement the change once OAuth project ownership and hosting preference are confirmed.
