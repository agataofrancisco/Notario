# Design

## Context

See [proposal.md](proposal.md) for the motivation and the three delta specs for behavioural requirements. The Flutter app stores tasks in Firestore and has a legacy SQLite representation. A task currently has `dataInicio`/`dataFim` and priority but no separate deadline. Existing capacity validation and rescheduling are repository methods focused on the date chosen in the form.

Google sign-in currently returns a `GoogleSignInAccount` without exchanging it for a Firebase credential. `GoogleCalendarService` creates a second `GoogleSignIn` instance and prompts independently, so authentication and Calendar authorization can diverge. The login screen also embeds a web client ID in source.

## Goals / Non-Goals

**Goals:**

- Add a backwards-compatible optional deadline and generate explainable, local focus candidates.
- Keep automated planning advisory-only: user confirmation controls task starts and schedule changes.
- Establish Firebase-backed Google identity and a shared Calendar authorization boundary.
- Make the changed flows testable and usable on small mobile viewports.
- Use SQLite as the immediate agenda source for tasks and imported Google activities; remote sync is queued and retryable.
- Store timed instants in UTC and derive day windows and notification wall times in `Africa/Luanda`; keep Google all-day entries on their civil date.
- Represent focusable Google Tasks and Calendar Events as local task records. Calendar completion is app-local; Google Tasks completion is synchronized to Tasks API.
- Preserve a Google Calendar all-day event's Luanda civil date without treating the event as a 24-hour focus block; use a 09:00, 30-minute editable planning slot because the external event supplies no focus interval.
- Treat Google Tasks `due` as a civil date: use 09:00 Africa/Luanda as its planning slot and the end of that Luanda day as its local deadline, since Google's Tasks API ignores the time portion of `due`.
- Compute completed planned capacity from actual focus minutes, so early completion releases the unused planned minutes.

**Non-Goals:**

- No generative model, remote recommendation service, user profiling, or paid AI integration.
- No automatic rescheduling, conflict resolution across external calendars, or two-way edits of arbitrary Google Calendar events in this change.
- No Calendar sync for unauthenticated users and no storage of OAuth client secrets in the app.

## Decisions

### Optional `deadline` is stored as a nullable timestamp

Add `DateTime? deadline` to the domain entity and map it to `deadline` in Firestore and `deadline` in SQLite. The task editor supplies an opt-in deadline picker, validates it against the calculated planned end, and legacy tasks deserialize with `null`.

This preserves existing schedules and keeps a deadline distinct from the intended execution slot. A required deadline was rejected because it would force migration decisions for all existing tasks and make lightweight task capture slower.

### A pure deadline guidance service calculates ranked candidates

Create a domain-level service that accepts a `now`, the user's pending tasks, and remaining usable minutes. It produces an immutable result containing at most three candidates and individual reason tokens/labels. It excludes completed, cancelled, skipped, already-active, and non-fitting tasks.

The initial score is lexicographic, not probabilistic: overdue first; then fewer minutes to deadline; then higher priority; then shorter fit/slack; then stable planned date/id. Only tasks with a deadline participate in proactive recommendations for the first release. The service receives the clock as an argument so boundary conditions are unit-testable and output is reproducible.

This was chosen over an LLM because it meets the stated no-cost constraint, is auditable, and gives a direct reason such as “Alta prioridade — termina em 2 dias”. A single numeric black-box score was rejected because it is harder to explain and tune safely.

### Daily UI asks for recommendations after today's plan is complete

The daily task/dashboard state derives whether today's planned pending tasks are complete and determines remaining capacity using existing work-hour configuration and scheduled/Calendar occupancy when Calendar is connected. It invokes the guidance service only then and displays a compact focus card or a calm completion state.

“Start” opens the existing execution route after confirmation. “Schedule” opens the task form with the candidate preselected; “Dismiss” is view-local and makes no data mutation. No data is changed solely by calculating or showing guidance.

### One Google account boundary serves Firebase identity and Calendar scopes

Refactor authentication so Google identity creates a Firebase Google credential from Google ID/access tokens and Firebase becomes the source of authenticated application user state. Encapsulate Google account/scopes in a shared session/authorization service used by Calendar operations. Identity sign-in asks only for identity/email; Calendar scope is requested incrementally when the user explicitly connects Calendar or initiates Calendar-backed behaviour.

This prevents duplicate pickers and unnecessary sensitive scope requests. Requesting Calendar scope during every login was rejected because Calendar is optional and consent should be contextual. Google configuration will be supplied by Firebase/platform files and documented build configuration; hard-coded app client IDs and any client secrets are removed from Dart source.

### Calendar failure is non-blocking and observable

Calendar operations return a typed connection/sync result rather than treating a missing or expired token as a successful empty response. Task creation and updates persist locally/Firestore first; a failed sync sets the existing task sync indicator to pending/needs-attention and exposes a reconnect action. Calendar disconnect revokes/disconnects local authorization and stops future synchronization without deleting task data.

Deleting a Notário-created task with a linked Google event writes a durable SQLite tombstone before removing the local task. The periodic sync retries that remote deletion and stores failure count/error; deleting an imported Calendar event removes only its local cache row and never deletes the user's remote event. A remote 404 counts as success so an already-removed event does not retry forever.

### UI/UX review is a delivery gate, not a design guess

Widget tests cover the changed states. A manual QA checklist records each changed screen at compact and standard mobile viewport widths, plus keyboard, loading, empty, validation/error, and permission states. Findings that block reachability, comprehension, or contrast are fixed before calling the change ready.

## Risks / Trade-offs

- [FireStore documents and SQLite rows predate deadlines] → Deserialize `deadline` as nullable; add a non-destructive SQLite migration and test legacy maps.
- [Deadline/time-zone ambiguity] → Store timestamps consistently, render in the user's local zone, and compute urgency from an injected local `now`.
- [Existing Firestore capacity queries omit tasks scheduled before today but still pending] → Scope first release to unscheduled/future candidates with deadlines and document any later backlog policy separately.
- [Google configuration is incomplete in the owner's Firebase/Google project] → Implement clear configuration error handling and provide a verified setup checklist (provider, SHA fingerprints, OAuth consent screen, Calendar API, platform config).
- [Calendar APIs/scopes can be denied or revoked] → Keep task persistence independent; expose disconnected/reconnect state rather than blocking the workflow.
- [Capacity calculations are approximate] → Treat suggestions as optional, state the available-time basis in the explanation, and never auto-reschedule.

## Migration Plan

1. Add the nullable model fields and serialization with read compatibility; deploy required Firestore index changes before the UI begins relying on the queries.
2. Release deadline capture and guidance behind normal client rollout; existing tasks receive no synthetic deadline.
3. Replace Google login with Firebase credential exchange, remove the hard-coded client ID, and add Calendar connection status/reconnect UI.
4. Configure and verify Google provider, SHA fingerprints, OAuth consent screen, and Calendar API in the Notário Firebase/Google project before release signing.
5. Run automated tests and the documented manual UI/UX pass before distribution.

Rollback: clients without the new build ignore the nullable field. If Calendar authorization fails in production, disable Calendar sync via the existing feature flag while leaving login, tasks, deadlines, and local guidance operational.

## Open Questions

- Which supported targets are in the first release (Android only, or also iOS and web)? The answer affects the final OAuth checklist and device verification matrix, but not the outlined architecture.
