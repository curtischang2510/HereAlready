# Changelog

All notable changes to HereAlready are recorded here, newest first.
Format: `## [YYYY-MM-DD] — <summary>`

---

## [2026-05-07] — MapKit Migration + MVP Core Build

### Added
- **MapKit** replaces Google Maps SDK — no API key, no CocoaPods, smaller binary
- **AppContainer** — owns `LocationManager` and `TripMonitor` at app scope; both injected via SwiftUI `.environmentObject`
- **TripMonitor** — distance monitoring via `CLLocation.distance(from:)`, alert deduplication (`hasAlerted` flag), `CLCircularRegion` geofencing for background alerts
- **LocationManager** — publishes `CLLocation` (not just coordinate) so accuracy can be checked; adds `startMonitoringRegion` / `stopMonitoringAllRegions` and `regionEnteredPublisher`
- **SearchViewModel** — real `MKLocalSearch` with 300ms debounce; stores selected `MKMapItem` including coordinate
- **Cute van marker** (🚐) — white card, pulsing blue ring, rotates to face direction of travel when GPS heading is available
- **Animated destination pin** — red gradient circle with gentle bounce, appears when a trip is active
- **Three-state sliding panel** — collapsed (search bar peeking) / partial (destination selected, ~40% visible) / expanded (searching); drag-to-snap supported
- **Trip configuration UI** — threshold picker (300m / 500m / 1km), Start/Stop button with gradient, live distance display (turns green within threshold)
- **Permission denied overlay** — full-screen blocker with deep-link to iOS Settings
- **Background location** — `UIBackgroundModes: location` added to `Info.plist`; `Always` authorization requested on trip start
- **CLAUDE.md** — project instructions, agent rules, documentation maintenance policy
- **docs/** — PRODUCT_SPEC, ARCHITECTURE, EXECUTION_PLAN, RELIABILITY, PRIVACY_SECURITY, TESTING, DECISIONS

### Changed
- Default simulator map centre set to **Singapore** (1.3521°N, 103.8198°E) — previous default was Sydney
- `Map.swift` renamed struct from `Map` to `MapView` to avoid collision with `MapKit.Map`
- `LocationManager.lastKnownLocation` type changed from `CLLocationCoordinate2D?` to `CLLocation?` to expose accuracy info

### Removed
- Google Maps SDK (`GoogleMaps` + `Google-Maps-iOS-Utils` CocoaPods)
- `AppDelegate` Google Maps SDK initialization
- CocoaPods integration fully deintegrated (`pod deintegrate`)

### Known Issues / Not Yet Done
- `SearchViewModelTests` and `TripMonitorTests` not yet written (stubs only in test target)
- Trip state not persisted to `UserDefaults` — active trip lost on force-quit
- No in-app alert when app is foregrounded at threshold crossing (only local notification)

---

## [2026-05-07] — Initial Commit

- SwiftUI app skeleton
- Google Maps map view with user location dot
- Search bar UI with hardcoded place list (NUS, NTU, SMU)
- Sliding bottom panel
