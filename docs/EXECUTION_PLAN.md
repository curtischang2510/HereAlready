# Execution Plan: HereAlready MVP

Last updated: 2026-05-07

## Current State

| Feature | Status |
|---------|--------|
| Map rendering (MapKit) | Done |
| User location tracking (foreground) | Done |
| Sliding panel UI (three states) | Done |
| Real place search (MKLocalSearch) | Done |
| Destination pin on map | Done |
| Distance threshold picker | Done |
| Trip start/stop control | Done |
| Distance calculation | Done |
| Notification/alert trigger | Done |
| Alert deduplication | Done |
| Background monitoring (geofencing) | Done |
| Permission denial handling (UI overlay) | Done |
| Recent searches (top 10, persisted) | In progress |
| Trip state persistence (UserDefaults) | Not started |
| In-app foreground alert banner | Not started |

---

## Phase 0 — Architecture Cleanup ✅

All tasks complete. MapKit replaced Google Maps; `LocationManager` lifted to app scope; `TripMonitor` created; `SearchViewModel` stores real `MKMapItem`.

---

## Phase 1 — Real Destination Search ✅

`MKLocalSearch` with 300ms debounce. Selected `MKMapItem` stored on `SearchViewModel`. Destination pin shown on map when trip is active.

---

## Phase 2 — Trip Configuration & Start/Stop ✅

Threshold picker (300m / 500m / 1km). Start/Stop buttons wired to `TripMonitor`. Live distance display with numeric transition animation.

---

## Phase 3 — Alert Trigger ✅

Distance calculated on each `CLLocation` update via `CLLocation.distance(from:)`. Alert fires once per trip (`hasAlerted` flag). `UNUserNotificationCenter` local notification delivered immediately on threshold crossing.

---

## Phase 4 — Background Monitoring ✅

`CLCircularRegion` geofencing registered on trip start. `didEnterRegion` delegate fires `regionEnteredPublisher` → `TripMonitor.fireAlert()`. `UIBackgroundModes: location` in `Info.plist`. `requestAlwaysAuthorization` called on trip start.

---

## Phase 5 — Recent Searches

**Goal:** Surface the user's last 10 destinations so they don't have to retype common routes.

Tasks:
1. Add `RecentSearch` Codable struct (name, subtitle, coordinate).
2. Add `recentSearches: [RecentSearch]` to `SearchViewModel`, load from UserDefaults on init.
3. On destination select, prepend to list, cap at 10, persist to UserDefaults.
4. Show recent searches section in `SearchPage` when field is focused and empty.
5. Tapping a recent search selects it as destination (same path as live results).

---

## Phase 6 — Remaining Polish (Not Started)

Tasks:
1. Persist active trip state to `UserDefaults` — restore `TripMonitor` state on app relaunch so monitoring survives force-quit.
2. In-app foreground alert — show a visible banner + haptic when app is foregrounded at threshold crossing (currently only a local notification fires).
3. Notification denied fallback — inform user that alerts may not work if notification permission is denied.

---

## Out of Scope for MVP

- User accounts / cloud sync
- Route or transit guidance
- Full trip history
- Social/sharing features
- Custom alarm sounds
