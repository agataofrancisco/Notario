# Tasks

## 1. Deadline data foundation

- [x] 1.1 Add nullable deadline support to the task domain entity and Firestore/SQLite serialization, including a non-destructive SQLite migration; verify legacy maps and new deadline round-trips with unit tests.
- [x] 1.2 Add deadline validation helpers and local-time status formatting (overdue, today, soon, later); verify boundary cases using an injected fixed clock.
- [x] 1.3 Update Firestore indexes/rules only where deadline queries require them and document the deployment command; verify the emulator or deployed rules allow each user only their own deadline-bearing tasks.

## 2. Deterministic focus guidance

- [x] 2.1 Implement a pure deadline-guidance service that filters ineligible tasks and returns at most three ranked, reason-bearing candidates; verify deterministic ordering for overdue, proximity, priority, capacity-fit, and ties.
- [x] 2.2 Derive today's completed-plan and remaining-capacity state from task/calendar availability without mutating tasks; verify no candidate is produced when capacity or eligible tasks are absent.
- [x] 2.3 Add BLoC/repository integration for requesting and refreshing guidance after task completion or schedule changes; verify state transitions with BLoC tests.
- [x] 2.4 Add deadline controls to task create/edit and deadline indicators to task surfaces; verify valid deadline creation, clearing, and rejection of a deadline before planned end with widget tests.
- [x] 2.5 Add the daily focus card/dialog with explicit Start, Schedule, and Dismiss actions; verify actions require confirmation where applicable and dismissal does not mutate any task.

## 3. Firebase Google sign-in and Calendar authorization

- [x] 3.1 Refactor Google identity sign-in to exchange Google tokens for Firebase Auth credentials and remove the source-embedded client ID; verify successful sign-in creates a Firebase-authenticated app user and cancellation restores the login UI.
- [x] 3.2 Create a shared Google authorization/session boundary used by identity and Calendar operations, with incremental Calendar scope requests; verify Calendar connect reuses the selected account rather than displaying an unrelated sign-in flow.
- [x] 3.3 Add Calendar connection status, connect/reconnect, and disconnect behavior; verify declined/revoked permission does not block local task creation and a reconnect action is visible.
- [x] 3.4 Make Calendar sync failures typed and non-blocking, preserving task persistence and recording sync attention; verify create/update/delete error paths against a failing Calendar client.
- [x] 3.5 Update Android, iOS, and web Firebase/OAuth configuration documentation (Google provider, SHA fingerprints, consent screen, Calendar API, and platform files); verify no client secret or fixed client ID remains in Dart source via `rg`.

## 4. UI/UX and accessibility validation

- [ ] 4.1 Review and correct changed login, task form, task list/dashboard, execution, and dialog layouts for compact and standard mobile viewports and keyboard-open states; verify every interactive control remains reachable by manual swipe/scroll testing.
- [ ] 4.2 Add semantics/text labels for deadline urgency, connection state, loading, errors, and focus actions; verify with Flutter widget tests and a screen-reader semantics inspection.
- [x] 4.3 Implement useful empty, failure, and disconnected states for focus guidance and Calendar; verify each state has plain-language context and a relevant next action.
- [ ] 4.4 Record the manual UI/UX walkthrough covering every changed screen and loading, success, empty, validation, error, and permission states; verify all blocking findings are fixed or explicitly accepted.

## 5. Integration verification

- [x] 5.1 Run `flutter analyze` and the full Flutter test suite after the changes; resolve failures introduced by this change.
- [ ] 5.2 Perform an authenticated-device smoke test for Google sign-in and Calendar connection using the configured Firebase project, then document the result and any external configuration blocker.
- [x] 5.3 Validate the OpenSpec change with `openspec validate add-deadline-guidance-and-google-auth --strict` and resolve all validation errors.

## Workflow follow-up

## 6. Offline agenda and shared focus mode

- [x] 6.1 Import Calendar events and Google Tasks into SQLite idempotently, preserving all-day civil dates without turning them into 24-hour focus blocks, and keeping source IDs; verify repeated refreshes do not duplicate rows.
- [x] 6.2 Route agenda reads, create/update/status changes, and notification restoration through SQLite first; retain pending work after remote errors.
- [x] 6.3 Normalize app civil time to Africa/Luanda and persist timed instants as UTC; verify day boundaries, all-day values, Google Task due-date planning/deadline mapping, and notification times.
- [x] 6.4 Open the same focus mode for local and imported items; persist elapsed/pause state across suspension and synchronize supported completion changes.
- [x] 6.5 Calculate daily completion and free time using actual minutes for completed activities and planned minutes for pending ones; verify early completion releases capacity.
- [ ] 6.6 Run analysis/tests and a device smoke test for offline start/complete, notification restore, Google refresh, and online retry.

- Implement this change with `/opsx:apply` when ready.
- Archive the change after implementation, review, and external OAuth verification are complete.
