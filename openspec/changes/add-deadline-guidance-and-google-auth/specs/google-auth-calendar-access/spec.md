# Spec Delta

## Purpose

Provide a reliable Google identity and calendar authorization journey that keeps the user in control of permissions and uses one coherent authenticated session.

## ADDED Requirements

### Requirement: Google sign-in authenticates the application session
The system SHALL authenticate a user who completes Google sign-in with Firebase Authentication and SHALL expose the resulting authenticated application user to the rest of the app.

#### Scenario: Successful Google sign-in
- **WHEN** a user completes the Google account picker and grants identity access
- **THEN** the app enters the authenticated state with that Firebase user and navigates to the authenticated experience

#### Scenario: User cancels Google sign-in
- **WHEN** a user closes or cancels the Google account picker
- **THEN** the app remains on the login screen and returns to an actionable, non-loading state without showing a false success

#### Scenario: Google sign-in fails
- **WHEN** identity authentication fails due to configuration, network, or provider error
- **THEN** the app shows an understandable error and provides a way to retry or use another supported sign-in method

### Requirement: Calendar access is an explicit, reusable permission
The system SHALL request Google Calendar permission only when calendar functionality is enabled or the user elects to connect it, and SHALL reuse the authenticated Google account instead of presenting unrelated sign-in flows.

#### Scenario: User connects Calendar
- **WHEN** an authenticated user opts to connect Google Calendar and grants the requested Calendar scope
- **THEN** the app marks Calendar as connected and can access the selected account's permitted calendar data

#### Scenario: Calendar permission is declined
- **WHEN** a user declines the Calendar permission request
- **THEN** task creation and local deadline guidance remain available and the app explains that Calendar sync is not connected

#### Scenario: Calendar token is no longer valid
- **WHEN** a Calendar operation detects expired or revoked authorization
- **THEN** the app preserves the local task operation, marks sync as needing attention, and offers a reconnect action

### Requirement: Calendar connection is visible and revocable
The system SHALL show whether Calendar is connected, disconnected, or needs reconnection, and SHALL let the user disconnect Calendar without deleting local tasks.

#### Scenario: User disconnects Calendar
- **WHEN** a user confirms Calendar disconnection
- **THEN** future Calendar synchronization stops, local tasks remain intact, and the UI reflects the disconnected state

### Requirement: Authentication secrets remain out of source code
The system MUST obtain OAuth configuration from platform/Firebase configuration and build-time environment rather than embedding client secrets in application source code.

#### Scenario: Production build is inspected
- **WHEN** the application is prepared for release
- **THEN** no OAuth client secret is present in the Flutter source or version-controlled application configuration
