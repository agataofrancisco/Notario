# Spec Delta

## Purpose

Define deadlines and transparent focus guidance so users can use free time on work most likely to become urgent without relying on paid AI services.

## ADDED Requirements

### Requirement: Tasks support an optional deadline
The system SHALL let a user set, view, edit, and clear an optional deadline separate from a task's planned start and end. A deadline earlier than the planned end MUST be rejected with a clear corrective message.

#### Scenario: User sets a valid deadline
- **WHEN** a user saves a task whose deadline is after its planned end
- **THEN** the task persists the deadline and displays it wherever deadline context is shown

#### Scenario: User enters an impossible deadline
- **WHEN** a user attempts to save a deadline before the planned task end
- **THEN** the task is not saved until the user chooses a valid deadline or clears it

#### Scenario: Existing task has no deadline
- **WHEN** an existing task created before this capability is loaded
- **THEN** it remains usable with no deadline and no migration error

### Requirement: Deadline urgency is understandable
The system SHALL identify pending tasks as overdue, due today, due soon, or scheduled beyond their deadline from the device's local current time, and SHALL present the corresponding deadline context in user-facing language.

#### Scenario: Deadline is overdue
- **WHEN** a pending task's deadline is before the current time
- **THEN** the task is visibly identified as overdue and ranks ahead of otherwise comparable non-overdue tasks

#### Scenario: Deadline is approaching
- **WHEN** a pending task has a future deadline inside the configured near-term horizon
- **THEN** the task displays its remaining deadline context without being labeled overdue

### Requirement: Daily focus suggestions are deterministic and consent-based
The system SHALL offer up to three pending, feasible tasks when the user's planned work for the current day is complete and free capacity remains. Suggestions MUST rank overdue status, deadline proximity, priority, and fit in available time using local deterministic rules, and SHALL include a human-readable reason.

#### Scenario: Free time has a relevant candidate
- **WHEN** the current day's planned pending tasks are complete and a pending task fits in the remaining capacity
- **THEN** the system presents the highest-ranked candidate with its deadline, priority, duration, and reason

#### Scenario: No suitable candidate exists
- **WHEN** there is no pending task that fits in the remaining capacity or has deadline context
- **THEN** the system does not show an empty or misleading focus suggestion

#### Scenario: User acts on a suggestion
- **WHEN** a user chooses to start or schedule a suggested task
- **THEN** the system requests the applicable confirmation and applies only the action chosen by the user

#### Scenario: User dismisses a suggestion
- **WHEN** a user dismisses a focus suggestion
- **THEN** no task schedule, state, or deadline is changed

### Requirement: Guidance does not depend on paid AI
The system SHALL calculate deadline urgency and focus suggestions from locally available task and calendar-capacity data without sending task content to a paid generative AI or model service.

#### Scenario: User has no model subscription
- **WHEN** a user creates tasks and completes planned work
- **THEN** deadline guidance remains available without an AI account, API key, or usage charge
