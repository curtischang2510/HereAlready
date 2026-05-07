# CLAUDE.md

## Project
HereAlready is a mobile app that helps users avoid missing their stop on public transport.

The user sets:
- a destination location
- a distance threshold, e.g. 300m, 500m, 1km
- an alarm/alert preference

When the user is within the selected distance from the destination, the app should trigger an alert to wake them up.

## Agent Operating Rules
- Do not make large rewrites without first writing a short plan.
- Prefer small, reviewable changes.
- Before coding, inspect relevant files and summarize the current architecture.
- After coding, run available tests, linters, and type checks.
- If tests do not exist, propose minimal tests before implementing large features.
- Preserve existing user-facing behavior unless the task explicitly changes it.
- Ask for clarification only when blocked; otherwise make reasonable assumptions and record them in docs/DECISIONS.md.

## Source of Truth
Read these files before making product or architecture changes:
- docs/PRODUCT_SPEC.md
- docs/ARCHITECTURE.md
- docs/EXECUTION_PLAN.md
- docs/RELIABILITY.md
- docs/PRIVACY_SECURITY.md
- docs/TESTING.md

## Core Product Requirements
- User can select a destination.
- User can configure a distance threshold.
- App monitors location while trip alert is active.
- App alerts user when distance to destination is less than or equal to threshold.
- App should avoid repeated duplicate alarms for the same trip.
- App should handle permission denial gracefully.
- App should avoid excessive battery drain.

## Non-Negotiable Constraints
- Location permissions must be handled explicitly and respectfully.
- Do not collect or store unnecessary location history.
- Background location behavior must be documented clearly.
- Alarm/notification behavior must work reliably enough for the user to trust it.
- Any platform limitations must be documented rather than hidden.

## Development Workflow
For each task:
1. Read relevant docs.
2. Write a short implementation plan.
3. Make the smallest coherent change.
4. Add or update tests where possible.
5. Run tests/lint/type checks.
6. Update docs if behavior or architecture changes.
