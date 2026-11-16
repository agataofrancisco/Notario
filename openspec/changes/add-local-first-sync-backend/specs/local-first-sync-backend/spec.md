# Spec Delta

## Purpose

Provides optional authenticated progress backup while preserving SQLite as the only durable store for activities and task details.

## ADDED Requirements

### Requirement: Offline-first operations
The system SHALL create, edit, start, complete, and display activities from the device's durable local store without requiring a backend response.

#### Scenario: Device is offline
- **WHEN** a person creates and completes a task without connectivity
- **THEN** the task state, actual duration, progress, and local reminders SHALL be retained on the device

#### Scenario: Backend is unavailable
- **WHEN** the backup service returns an error
- **THEN** the app SHALL keep the local operation successful and queue it for a later attempt

### Requirement: Authenticated per-user progress backup
The backend SHALL accept progress synchronization requests only with a valid Google ID token and SHALL scope all records to the token's verified subject identifier.

#### Scenario: Valid backup request
- **WHEN** a signed-in person sends a valid sync request
- **THEN** the backend SHALL read or write only records associated with that person's subject identifier

#### Scenario: Invalid or expired token
- **WHEN** a sync request has no valid Google ID token
- **THEN** the backend SHALL return an authentication error and SHALL not read or write activity data

### Requirement: Progress-only data boundary
The backend SHALL store only progress events and aggregates: user identifier, event ID, completion timestamp, actual elapsed minutes, aggregate counters, and schema/version metadata. It SHALL NOT accept task title, description, schedule, Google event ID, task payload, or Calendar/Tasks token.

#### Scenario: Task completion is uploaded
- **WHEN** a person completes a local task and backup is enabled
- **THEN** the upload SHALL contain only a progress event with completion time and actual elapsed minutes

#### Scenario: Task record is included accidentally
- **WHEN** a client sends task content or a Google identifier to the progress endpoint
- **THEN** the backend SHALL reject the request without persisting its data

### Requirement: Idempotent progress synchronization
The backend SHALL accept immutable progress events identified by a client-generated operation ID and SHALL apply each operation no more than once.

#### Scenario: Retried network request
- **WHEN** a client resends a progress event after an uncertain network result
- **THEN** the backend SHALL return the prior result without duplicating the event or aggregate totals

### Requirement: Conflict-safe progress reconciliation
The backend SHALL return progress events newer than the client's sync cursor and SHALL deduplicate identical operation IDs without deleting valid events from another device.

#### Scenario: Progress is recorded on two devices
- **WHEN** two devices upload distinct progress events while offline
- **THEN** the backend SHALL retain both events and recalculate the user's aggregates from the deduplicated event set

### Requirement: Minimal data retention
The backend SHALL store only progress records required for backup and SHALL provide authenticated account-data deletion.

#### Scenario: Account data deletion
- **WHEN** a signed-in person requests deletion of cloud backup data
- **THEN** the backend SHALL delete that person's backup records and return a completion result without deleting their device-local data
