# Decisions: HereAlready

Last updated: 2026-05-07

Record of non-obvious choices, assumptions, and open questions. Add an entry whenever making a judgment call during implementation.

---

## Closed Decisions

### Map SDK: MapKit chosen (not Google Maps)
**Status:** Decided.

MapKit was chosen over Google Maps SDK. Reasoning: removes CocoaPods, API key management, and AppDelegate boilerplate; better privacy (no queries to Google for basic map use); no binary size cost; `MKLocalSearch` is sufficient for MVP destination search. CocoaPods fully deintegrated.

---

### Background monitoring: Geofencing (`CLCircularRegion`)
**Status:** Decided.

Battery-efficient; works even if app is terminated (iOS relaunches on region entry). Accuracy (~100m) is acceptable for 300m+ thresholds. Continuous GPS (`startUpdatingLocation`) is used only for foreground map display.

---

### Sliding panel approach
**Status:** Decided.

Offset-based sliding panel (not a native `sheet`). Reason: the map must be fully visible behind the panel. A native sheet covers the map.

---

### Location accuracy filter: no upper bound
**Status:** Decided.

`TripMonitor.update()` only rejects locations where `horizontalAccuracy < 0` (invalid fix). An earlier guard (`<= 100m`) was removed because simulator GPS and weak-signal device readings often exceed 100m accuracy while still being usable for coarse trip alerts. Negative accuracy is the canonical CoreLocation signal for "this fix is invalid."

---

### Distance seeding on trip start
**Status:** Decided.

`TripMonitor.start()` immediately calls `update(location: lastKnownLocation)` after setting `isActive = true`. Without this, the Combine subscription only fires on the *next* location event, causing the distance display to hang on "Calculating distance…" indefinitely if the device hasn't moved.

---

### Recent searches: lightweight Codable struct (not MKMapItem)
**Status:** Decided.

`MKMapItem` is not `Codable` and cannot be persisted directly. Instead, a `RecentSearch` struct captures only what we need: name, subtitle, latitude, longitude. This is sufficient to reconstruct a tappable destination row and pass a coordinate to `TripMonitor.start()`.

---

## Assumptions Made

- Target iOS 18.3+. SwiftUI APIs used are compatible.
- App is single-user, single-device. No sync needed.
- "Alert" means a local notification with sound — not a Critical Alert (which requires Apple entitlement).
- The user typically sets a destination before boarding transport, not mid-journey.
- Top 10 recent searches is sufficient; no UI to explicitly delete individual entries at MVP.
