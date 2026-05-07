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
- Destination selection via `MKLocalSearch`
- Recent searches (top 10, persisted across sessions)
- Distance threshold selection (300m / 500m / 1km)
- Start/stop trip monitoring
- Live distance display while trip is active
- Distance calculation via `CLLocation.distance(from:)`
- Local notification alert trigger on threshold crossing
- Alert deduplication (fires once per trip)
- Background monitoring via `CLCircularRegion` geofencing
- Permission handling (location + notification)
- Permission denied overlay with Settings deep-link

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
