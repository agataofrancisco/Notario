# Manual UI/UX walkthrough

## Device and scope

- Device: itel A665L, Android 13, 720 × 1612 px at 320 dpi (about 360 × 806 dp).
- Theme: dark mode.
- Screens inspected directly: dashboard, new-task form, focus mode for a Calendar-imported activity, and the focus-exit confirmation.
- The app had an authenticated session and Calendar showed as connected before this walkthrough.

## Observations

| Screen/state | Result | Follow-up |
|---|---|---|
| Dashboard, top | Progress, free-time count, month calendar, Calendar connection text, refresh action, and task list are readable. The agenda uses one list for imported and local activities. | No blocking issue observed. |
| Dashboard, first loading frame | Automated widget coverage verifies that an initial task load no longer flashes the empty-agenda state. | Initial loading now remains explicit until the first local read finishes. |
| Focus guidance card | Start and Schedule both show confirmation dialogs. Cancelling leaves the task pending; Dismiss hides only the suggestion and preserves its status and scheduled time. | Automated action-flow coverage added. |
| Empty agenda, short remaining viewport | The empty state can scroll when the dashboard has little remaining height, avoiding a RenderFlex overflow. | Automated compact-viewport coverage added. |
| Dashboard, scrolled to the end | All three visible activity cards can be reached. The add-task button remains fixed; the last card can be scrolled clear of it. | No blocking issue observed. |
| New task | Title, description, date, time, optional deadline, duration, and priority fit in a vertically scrollable form. The deadline control is visible and labelled. | Keyboard-open state was not verified on the physical device. |
| Focus mode, imported Calendar activity | Imported activity opens the shared focus screen. Its lengthy description occupies much of the first viewport; scrolling reaches the timer, pause, and complete actions. | Consider collapsing long descriptions in a future UX pass; the actions remain reachable. |
| Focus exit confirmation | The dialog explains that the timer will pause and can be resumed. Cancel and exit actions are visible. | The exercised activity's local status/focus row was restored after the check. |

## Not verified on device

- Login screen and Google account-picker cancellation; an already-authenticated session was present.
- Keyboard-open task-form layout and accessibility screen-reader output.
- Narrower viewport and light theme.
- Offline cache and online retry. Wi-Fi and mobile data were disabled for this check, then the Android device disappeared from ADB before the cached agenda could be inspected or connectivity restored through ADB. Do not treat the offline device smoke test as passed.
- Google sign-in / Calendar OAuth consent was not repeated during this walkthrough.
- A Pixel 6 API 36 emulator was launched for a follow-up smoke attempt. Its cold boot overloaded the host: Android recorded ANRs for both Notário and Pixel Launcher. Notário's ANR reason was waiting for `SessionLifecycleService`; its main thread was still in Flutter's generated `path_provider` channel registration during activity startup, with no app-level synchronous work on the captured stack. Firebase Instance ID also returned `AUTHENTICATION_FAILED` in the emulator. The login screen eventually rendered behind system ANR dialogs, so this attempt is inconclusive and does not count as a successful device or OAuth smoke test.

## Automated evidence

- The full `flutter test --no-pub` suite passed: 38 tests (2026-11-18), including Firebase credential exchange, same-account incremental Calendar scopes, declined/revoked permission, local SQLite create, reconnect visibility, failed Calendar create/update/delete retries, Google Tasks deadline mapping, all-day/timed event mapping, and focus-guidance empty/error states.
- `flutter analyze --no-pub` passed with no issues after the sync and accessibility changes (61.5 seconds; 2026-11-18).
- The compact form/card widget tests passed, including valid deadline selection, rejection of a deadline before planned end, clearing a deadline, and a simulated keyboard inset with the save action above the keyboard.
- The focus-guidance widget test covers Start, Schedule, and Dismiss behavior; the first two require confirmation and cancellation preserves the task.
- Firestore Emulator rules tests passed (2 tests): owner-only access for deadline-bearing tasks and notes, and rejection of forged or changed ownership.
- `openspec validate add-deadline-guidance-and-google-auth --strict` passed.
- Focus-session persistence, imported-row idempotence, early-completion capacity, and timezone boundaries have targeted tests. Google Tasks date-only and midnight-UTC due values retain their Luanda civil date, use 09:00 for planning, and are actionable as a local end-of-day deadline. Google all-day events retain their civil date and receive a 30-minute focus slot instead of consuming 24 hours; timed events retain their UTC interval.
- Device-only offline start/complete, notification restore, Google refresh, online retry, repeated OAuth consent, full manual UI states, and screen-reader inspection remain pending. The original Itel is currently absent from ADB, and the emulator attempt was inconclusive due to its system-level overload.
