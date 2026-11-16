# Spec Delta

## Purpose

Allows each Notário user to authenticate with a personal Google account and explicitly authorize access to that account's Calendar and Tasks data.

## ADDED Requirements

### Requirement: Google account identity
The system SHALL identify a signed-in person by the stable Google subject identifier in a verified ID token, not by email address or display name.

#### Scenario: First sign-in
- **WHEN** a person completes Google Sign-In with a valid ID token
- **THEN** the system creates or selects only that person's local profile and synchronization namespace

#### Scenario: Email address changes
- **WHEN** Google returns a changed email address for an existing subject identifier
- **THEN** the person retains access to the same local and backup data

### Requirement: Per-user Calendar consent
The system SHALL request Calendar and Tasks permissions from each person independently and SHALL use the resulting authorization only for that person's data.

#### Scenario: Two people use the same device
- **WHEN** a second person signs in and grants Calendar access
- **THEN** their import and synchronization SHALL NOT expose the first person's activities

#### Scenario: Calendar permission denied
- **WHEN** a person declines Calendar or Tasks consent
- **THEN** the app SHALL retain all local task functions and explain that Google import/sync is unavailable

### Requirement: Least-privilege authorization
The system SHALL request the narrowest Google scopes needed for the enabled feature and SHALL disclose Calendar/Tasks access in the consent flow.

#### Scenario: Read-only connection
- **WHEN** a person enables import only
- **THEN** the system SHALL request read access and SHALL NOT create or modify Google events

#### Scenario: Two-way connection
- **WHEN** a person enables export or completion sync
- **THEN** the system SHALL request the corresponding write access before the first write
