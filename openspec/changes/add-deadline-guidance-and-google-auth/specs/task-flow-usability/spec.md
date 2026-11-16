# Spec Delta

## Purpose

Ensure the changed task and authentication journeys remain clear, operable, accessible, and visually reliable on supported mobile screen sizes.

## ADDED Requirements

### Requirement: Changed screens remain reachable and scrollable
The system SHALL make all controls and confirmation actions in the login, task form, daily task, execution, and focus-guidance flows reachable on small mobile viewports, including when the keyboard is open.

#### Scenario: User opens a long task form on a small screen
- **WHEN** the task form exceeds the available viewport height
- **THEN** the user can scroll to every field, validation message, and save action without clipped controls

#### Scenario: User opens a dialog with detailed guidance
- **WHEN** a validation or focus-guidance dialog contains more content than the viewport
- **THEN** the dialog content and all actions remain scrollable and reachable

### Requirement: Important state is communicated accessibly
The system SHALL provide text labels and semantic meaning for primary actions, deadline status, loading state, errors, and focus-suggestion controls; colour alone MUST NOT convey urgency or connection state.

#### Scenario: Deadline status is presented
- **WHEN** a task is overdue or approaching its deadline
- **THEN** its status is available as readable text in addition to any visual colour or icon

#### Scenario: Authentication action is loading
- **WHEN** an identity or Calendar action is in progress
- **THEN** the initiating control communicates that it is busy and duplicate submission is prevented

### Requirement: Empty, error, and disconnected states are actionable
The system SHALL provide a plain-language explanation and a relevant next action whenever a changed screen has no tasks to suggest, cannot load required data, or lacks Calendar authorization.

#### Scenario: Dashboard has no focus recommendation
- **WHEN** the user has finished today's work but no task qualifies for a suggestion
- **THEN** the user sees a calm completion state rather than an empty placeholder

#### Scenario: Calendar is unavailable
- **WHEN** Calendar access is not connected or fails
- **THEN** the user can continue managing local tasks and is offered a clear connect or retry action where relevant

### Requirement: Changed flows receive viewport review
The release SHALL include a documented manual UI/UX pass through every changed screen and its loading, success, empty, validation, error, and permission states at supported mobile viewport sizes.

#### Scenario: Pre-release QA
- **WHEN** implementation of this change is ready for release validation
- **THEN** the QA record identifies the screens and states reviewed, observed issues, and their resolution or accepted follow-up
