# Notário Progress Backend

Small Go service for optional progress backup. It deliberately does **not**
store tasks, titles, notes, schedules, Google Calendar IDs, Google access
tokens, or refresh tokens.

## Stored data

For an authenticated Google subject, the service stores only:

- an idempotency operation ID;
- completion timestamp;
- actual minutes spent;
- completion count and total actual minutes derived from events.

## API

All protected endpoints require `Authorization: Bearer <Google ID token>`.

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/healthz` | Service health, no authentication. |
| `POST` | `/v1/progress/push` | Store 1–100 completion events idempotently. |
| `GET` | `/v1/progress/pull?cursor=0` | Read the caller's later events and aggregate totals. |
| `DELETE` | `/v1/account/data` | Permanently delete the caller's cloud progress. |

The push schema rejects unknown JSON properties. Sending fields such as
`title`, `description`, `schedule`, `taskId`, or `googleEventId` therefore
fails rather than leaking task content.

```json
{
  "events": [{
    "operationId": "a-client-generated-uuid",
    "completedAt": "2026-11-15T12:00:00Z",
    "actualMinutes": 30,
    "kind": "completed"
  }]
}
```

## Local development

1. Create `.env` from `.env.example` and set an OAuth client ID.
2. Run `docker compose --env-file .env up --build`.
3. Call `GET http://localhost:8080/healthz`.

For native execution, set `DATABASE_URL` and `GOOGLE_OAUTH_CLIENT_ID`, then
run `go run ./cmd/notario-progress`.

## OAuth requirements

The API verifies a Google ID token signature, issuer, expiry, and audience.
`GOOGLE_OAUTH_CLIENT_ID` must be a client ID in the Google project used by the
mobile app. The API does not call Calendar or Tasks and does not need a Google
service account.

## Privacy and retention

Progress events are retained until the authenticated person calls
`DELETE /v1/account/data`. Operational logs must redact Authorization headers
and request bodies. Deploy only behind HTTPS, configure a restricted database
account, and retain database backups for the minimum operational period.
