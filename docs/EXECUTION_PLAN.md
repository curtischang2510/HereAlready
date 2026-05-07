# Execution Plan: HereAlready MVP

## Current State (as of May 2026)

| Feature | Status |
|---------|--------|
| Map rendering | Done (Google Maps — may be replaced) |
| User location tracking (foreground) | Done |
| Sliding panel UI | Done |
| Destination search UI | Done (hardcoded data) |
| Real place search | Not started |
| Distance calculation | Not started |
| Distance threshold picker | Not started |
| Trip start/stop control | Not started |
| Alert / notification trigger | Not started |
| Alert deduplication | Not started |
| Background monitoring (geofencing) | Not started |
| Permission denial handling (UI) | Partial (logic only) |

---

## Phase 0 — Architecture Cleanup (Before Any New Features)

**Goal:** Fix structural problems before building on top of them. The existing code is a good sketch but needs restructuring.

Tasks:
1. **Decide on map SDK** — MapKit (recommended) or keep Google Maps. See `ARCHITECTURE.md`. If switching to MapKit: remove Pods, delete `AppDelegate.swift`, replace `GoogleMapsViewRepresentable` with `Map` from `MapKit`.
2. **Lift `LocationManager` to app scope** — Move it from inside `Map` view to `HereAlreadyApp` as a `@StateObject`, inject via `.environmentObject`.
3. **Create `TripMonitor`** — New `ObservableObject` service holding destination, threshold, active state, and alert logic. Inject via `.environmentObject` alongside `LocationManager`.
4. **Update `SearchViewModel`** to store a selected coordinate (not just a string) when a place is chosen.

Deliverable: app still looks and behaves the same, but services live at the right scope.

---

## Phase 1 — Real Destination Search

**Goal:** Replace hardcoded place list with real search results.

If using **MapKit:**
- Use `MKLocalSearch` with `MKLocalSearchRequest` on `searchText` changes (debounce ~300ms).
- Store the selected `MKMapItem` (contains coordinate) on `SearchViewModel`.
- Drop a pin on the map at the selected destination.

If using **Google Maps:**
- Add `GooglePlaces` pod.
- Call `GMSPlacesClient.findAutocompletePredictions`.
- Store selected `GMSPlace` coordinate.

---

## Phase 2 — Trip Configuration & Start/Stop

**Goal:** Let the user configure a threshold and start monitoring.

Tasks:
1. Add a distance threshold picker to `SearchPage` (segmented: 300m / 500m / 1km).
2. Add a "Start Alert" button (visible once destination is selected).
3. Wire button to `TripMonitor.start(destination:threshold:)`.
4. Add a "Stop" button that calls `TripMonitor.stop()`.
5. Show current distance to destination while trip is active (updated on each location update).

---

## Phase 3 — Alert Trigger (Foreground)

**Goal:** Alert fires when user is within threshold, while app is open.

Tasks:
1. In `TripMonitor`, on each `LocationManager` update, compute `CLLocation.distance(from:)`.
2. If distance ≤ threshold and `!hasAlerted`: set `hasAlerted = true`, fire alert.
3. Foreground alert: `UIAlertController` or a SwiftUI sheet/banner + haptic feedback.
4. Request `UNUserNotificationCenter` authorization for the background case.

---

## Phase 4 — Background Monitoring (Geofencing)

**Goal:** Alert fires when app is backgrounded or screen is locked.

Tasks:
1. Add `NSLocationAlwaysAndWhenInUseUsageDescription` to `Info.plist`.
2. Add `UIBackgroundModes` → `location` to `Info.plist`.
3. On trip start, request `requestAlwaysAuthorization` (explain to user why).
4. Register a `CLCircularRegion` with `CLLocationManager.startMonitoring(for:)`.
5. Handle `locationManager(_:didEnterRegion:)` in `LocationManager` — notify `TripMonitor`.
6. Fire a `UNUserNotificationCenter` local notification with sound.
7. Persist active trip state to `UserDefaults` so monitoring survives app restarts.
8. Test on a real device with location simulation.

---

## Phase 5 — Edge Cases & Polish

Tasks:
1. Permission denied UI — banner linking to Settings if location is denied.
2. Notification denied fallback — inform user alerts may not work.
3. Accuracy filter — ignore `CLLocation` updates where `horizontalAccuracy > 100`.
4. One-shot alert — ensure no repeated alarms for the same trip.
5. Handle app relaunch mid-trip — restore `TripMonitor` state from `UserDefaults`.

---

## Out of Scope for MVP

- User accounts / cloud sync
- Route or transit guidance
- Trip history
- Social/sharing features
- Custom alarm sounds
