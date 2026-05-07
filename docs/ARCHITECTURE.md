# Architecture: HereAlready

Last updated: 2026-05-07

## Current Implementation

### Entry Point
- `HereAlreadyApp.swift` — `@main` SwiftUI app struct. Owns `AppContainer` as a `@StateObject` and injects `locationManager` and `tripMonitor` via `.environmentObject`.
- `AppDelegate.swift` — Minimal; no third-party SDK init.
- `AppContainer.swift` — App-scoped service container. Instantiates `LocationManager` and `TripMonitor`; wires the dependency between them.

### File Breakdown

| File | Role |
|------|------|
| `HereAlreadyApp.swift` | App entry point, service injection |
| `AppDelegate.swift` | Minimal UIKit delegate |
| `AppContainer.swift` | Service container (LocationManager + TripMonitor) |
| `ContentView.swift` | Root view + three-state sliding panel layout |
| `Map.swift` | MapKit `Map` view, `VanMarkerView`, `DestinationMarkerView` |
| `SearchPage.swift` | Destination search panel UI |
| `SearchViewModel.swift` | `MKLocalSearch`, selected place, recent searches persistence |
| `LocationManager.swift` | `CLLocationManager` wrapper, geofencing, Combine publishers |
| `TripMonitor.swift` | Trip lifecycle, distance calculation, alert trigger |

---

## Service Graph

```
HereAlreadyApp
└── AppContainer (@StateObject)
    ├── LocationManager  → injected as @EnvironmentObject
    └── TripMonitor      → injected as @EnvironmentObject
            │
            └── subscribes to LocationManager.$lastKnownLocation (Combine)
                subscribes to LocationManager.regionEnteredPublisher (Combine)

ContentView
├── MapView              reads LocationManager from environment
└── SearchPage
    └── SearchViewModel  (@StateObject, owned by SearchPage)
        └── persists RecentSearch list to UserDefaults
```

---

## Key Design Decisions

### MapKit (not Google Maps)
Replaced Google Maps SDK and CocoaPods with system MapKit. No API key, no dependency manager, smaller binary. `MKLocalSearch` handles destination search adequately for MVP.

### Location scope
`LocationManager` is app-scoped (owned by `AppContainer`), not view-scoped. This ensures location updates are available to `TripMonitor` regardless of the view tree state.

### TripMonitor distance seeding
On `start()`, `TripMonitor` immediately seeds `distanceToDestination` using `locationManager.lastKnownLocation`. Without this, the Combine subscription only fires on *new* location events, causing the UI to hang on "Calculating distance…" if the device hasn't moved since the last update.

### Accuracy filter
`TripMonitor.update()` rejects only locations where `horizontalAccuracy < 0` (invalid fix). The original upper-bound guard (`<= 100m`) was removed because simulator GPS and low-signal real-device readings often report higher accuracy values that are still sufficient for coarse trip-distance alerts.

### Background monitoring
`CLCircularRegion` geofencing is the primary alert mechanism for background/terminated state — battery-efficient and works even when the app is killed. `startUpdatingLocation` (with `distanceFilter = 20m`) drives live foreground map display only.

---

## Recent Searches Persistence

`SearchViewModel` maintains a `recentSearches: [RecentSearch]` list (max 10) persisted to `UserDefaults`.

`RecentSearch` is a lightweight `Codable` struct storing only what `MKMapItem` cannot: name, subtitle, and coordinate. It is shown in the search panel when the field is focused but empty. Selecting a recent search repopulates the field and selects the destination, identical to a live search result.

---

## Dependencies

| Framework | Purpose |
|-----------|---------|
| MapKit | Map rendering, `MKLocalSearch` |
| CoreLocation | GPS, geofencing |
| Combine | Reactive location updates |
| UserNotifications | Local notifications |
| SwiftUI | UI |

No CocoaPods. No third-party dependencies.
