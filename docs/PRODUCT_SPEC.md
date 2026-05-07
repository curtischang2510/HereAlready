# Product Spec: HereAlready

## Problem
I often fall asleep on public transport and risk missing my stop.

## Goal
Allow users to set a destination and receive an alarm when they are within a custom distance from that destination.

## Core User Flow
1. User opens the app.
2. User selects or searches for a destination.
3. User chooses an alert radius, e.g. 300m, 500m, 1km.
4. User starts the trip alert.
5. App monitors the user's current location.
6. When distance to destination <= threshold, app triggers an alert.
7. User dismisses or stops the alert.

## MVP Features
- Destination selection
- Distance threshold selection
- Start/stop trip monitoring
- Distance calculation
- Notification/alarm trigger
- Permission handling
- Basic trip state display

## Out of Scope for MVP
- User accounts
- Social features
- Route optimization
- Payment features
- Full trip history
- Cloud sync

## Important Edge Cases
- User denies location permission.
- User turns off location services.
- User closes the app.
- App goes into background.
- GPS signal is inaccurate.
- User passes near destination but does not alight.
- User wants to cancel active monitoring.
- Alert triggers once and should not repeatedly spam.
