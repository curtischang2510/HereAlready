# Decisions: HereAlready

Record of non-obvious choices, assumptions made without explicit instruction, and open questions. Add an entry here whenever making a judgment call during implementation.

---

## Open Decisions

### Map SDK: MapKit vs Google Maps
**Status:** Undecided — needs confirmation from Curtis.

**Recommendation:** Switch to MapKit.
- Removes CocoaPods dependency, API key management, and `AppDelegate` boilerplate.
- `MKLocalSearch` is sufficient for destination search at MVP scope.
- Better privacy story (no queries to Google servers for basic map use).
- Smaller binary.

**If staying with Google Maps:** Restrict the API key in Google Cloud Console to this app's bundle ID before any release or public repo push.

---

### Background monitoring strategy: Geofencing vs Continuous GPS
**Status:** Decided — use geofencing (`CLCircularRegion`).

**Reasoning:**
- Battery-efficient: no continuous GPS polling in background.
- Works even if app is terminated — iOS relaunches app on region entry.
- Accuracy (~100m) is acceptable for 300m+ thresholds. For a 300m threshold, the effective trigger range is acceptable.
- Continuous GPS (`startUpdatingLocation` with background mode) is reserved for foreground map display only.

---

## Closed Decisions

### Sliding panel approach
**Decision:** Keep the existing sliding panel (`offset`-based) rather than a native `sheet`.
**Reasoning:** The map needs to be fully visible behind the panel. A native sheet covers the map.

---

## Assumptions Made

- Target iOS 18.3+ (set in Podfile). SwiftUI APIs used are compatible.
- App is a single-user, single-device app. No sync needed.
- "Alert" means an audible/visual notification — not a loud siren-style alarm (which would require Critical Alert entitlement from Apple).
- The user will typically set a destination before boarding transport, not during the journey (UX designed for pre-trip setup).
