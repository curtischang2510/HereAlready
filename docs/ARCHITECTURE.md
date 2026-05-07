# Architecture: HereAlready

## Current Implementation

### Entry Point
- `HereAlreadyApp.swift` — `@main` SwiftUI app struct. Attaches `AppDelegate` via `@UIApplicationDelegateAdaptor`.
- `AppDelegate.swift` — Initialises Google Maps SDK with an API key at app launch.

### Current File Breakdown

| File | Role |
|------|------|
| `HereAlreadyApp.swift` | App entry point |
| `AppDelegate.swift` | Google Maps SDK init |
| `ContentView.swift` | Root view + sliding panel layout |
| `Map.swift` | Google Maps view + owns `LocationManager` |
| `SearchPage.swift` | Destination search panel UI |
| `SearchViewModel.swift` | Search text/focus state, hardcoded place list |
| `LocationManager.swift` | `CLLocationManager` wrapper |

---

## Problems with Current Architecture

### 1. `LocationManager` is owned by `Map`
`LocationManager` is a `@StateObject` inside the `Map` view. This means:
- Only the map has access to location data.
- Trip monitoring (which needs to compare location to destination) cannot access it without prop-drilling or a global.
- Location updates stop if `Map` disappears from the view tree.

**Fix:** Lift `LocationManager` to the app level — either as a `@StateObject` on `HereAlreadyApp` or injected via the environment.

### 2. No trip state exists
There is no object responsible for: holding the destination, threshold, active monitoring state, or firing alerts. This needs to be a dedicated `TripMonitor` service, not logic scattered across views.

### 3. `SearchViewModel` has no real data
Place search is hardcoded to `["NUS", "NTU", "SMU"]`. The destination coordinate is never stored — selecting a place only updates a text field.

### 4. Google Maps SDK may be unnecessary
See the **Map SDK Decision** section below.

---

## Target Architecture

```
HereAlreadyApp
├── LocationManager          (@StateObject, app-scoped, injected via environment)
├── TripMonitor              (@StateObject, app-scoped, observes LocationManager)
│   ├── destination: CLLocationCoordinate2D?
│   ├── thresholdMetres: Double
│   ├── isActive: Bool
│   └── hasAlerted: Bool
└── ContentView
    ├── MapView              (reads LocationManager from environment)
    └── SearchPage
        └── SearchViewModel  (manages search text + selected place coordinate)
```

### Key principles
- Location is app-level state, not view state.
- `TripMonitor` is the single source of truth for trip lifecycle.
- Views observe published state; they do not own services.
- Alerts are triggered by `TripMonitor`, not by views.

---

## Map SDK Decision

**Open question:** Google Maps SDK vs MapKit.

| | Google Maps SDK | MapKit |
|--|----------------|--------|
| Cost | Free up to quota, then paid | Free, no quota |
| API key required | Yes | No |
| Place search | Google Places API (excellent) | `MKLocalSearch` (good enough for MVP) |
| Map quality | Generally better globally | Good, improves yearly |
| Privacy | Queries go to Google servers | On-device + Apple servers |
| Binary size | ~30MB added | 0 (system framework) |
| Background monitoring | N/A (map only) | N/A (map only) |

**Recommendation:** Switch to MapKit for MVP. `MKLocalSearch` handles destination search adequately. This eliminates the API key, the CocoaPods dependency, and the `AppDelegate` SDK init. If map quality becomes an issue post-MVP, switching back is straightforward.

---

## Background Monitoring Approach

Use `CLCircularRegion` geofencing as the primary alert mechanism:
- Battery-efficient (no continuous GPS polling).
- Works when app is backgrounded or terminated (iOS relaunches the app on boundary crossing).
- Accuracy is sufficient for 300m+ thresholds.

Use `startUpdatingLocation` (with `distanceFilter = 20`) only while the app is foregrounded, to drive the live map display.

---

## Dependencies (Current)

| Pod | Version | Purpose | Keep? |
|-----|---------|---------|-------|
| `GoogleMaps` | 9.4.0 | Map rendering | Remove if switching to MapKit |
| `Google-Maps-iOS-Utils` | 6.1.0 | Map utilities | Remove if switching to MapKit |

CoreLocation — system framework, no change.
