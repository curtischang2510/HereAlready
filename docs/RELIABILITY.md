# Reliability: HereAlready

The core promise of HereAlready is that the alert fires before the user misses their stop. This document captures known risks, platform constraints, and mitigation strategies.

---

## 1. Background Location

### Risk
iOS aggressively suspends apps in the background to save battery. A suspended app cannot process location updates.

### Constraints
- `startUpdatingLocation` with background modes enabled keeps the app alive but drains battery.
- `startMonitoringSignificantLocationChanges` uses cell-tower triangulation — low battery cost but ~500m accuracy, which may be too coarse for a 300m threshold.
- Region monitoring (`startMonitoring(for:)`) triggers on entering/exiting a geofence — this is the most battery-efficient approach for a fixed destination.

### Decision (to be confirmed)
Use `CLCircularRegion` monitoring (geofencing) as the primary alert mechanism for background. Use `startUpdatingLocation` only while the app is in the foreground for live map display.

**Platform limitation to document to user:** On iOS, background location requires "Always" permission. The user must explicitly grant this. If only "When In Use" is granted, alerts will only fire while the app is foregrounded.

---

## 2. Alert Deduplication

### Risk
Location updates can arrive multiple times in quick succession within the threshold radius, causing repeated alarms.

### Mitigation
- `TripMonitor` keeps a `hasAlerted: Bool` flag per trip session.
- Once the alert fires, further location updates are ignored until the user starts a new trip.
- On trip cancel/stop, reset the flag.

---

## 3. GPS Accuracy

### Risk
`CLLocation.horizontalAccuracy` can be high (>100m) in tunnels, underground stations, or dense urban areas — exactly where public transport users are most likely to be.

### Mitigation
- Filter out location updates where `horizontalAccuracy > 100`.
- Do not trigger alerts based on inaccurate readings.
- **Known limitation:** alerts may be delayed or not fire underground. This must be communicated to the user.

---

## 4. App Termination

### Risk
If the user force-quits the app, `CLLocationManager` delegate calls stop.

### Mitigation
- Region monitoring (`CLCircularRegion`) can relaunch a terminated app when the boundary is crossed — iOS delivers the event to the app delegate.
- Active trip state must be persisted to `UserDefaults` so `TripMonitor` can be reconstructed on relaunch.
- **Known limitation:** significant location change monitoring and region monitoring do not work if the user has explicitly denied "Always" location permission after force-quitting.

---

## 5. Notification Delivery

### Risk
Local notifications may not play sound if the device is in Silent mode or Do Not Disturb.

### Mitigation
- Use `UNNotificationSound.defaultCritical` if entitlement is available (requires Apple approval for critical alerts).
- Otherwise, fall back to `UNNotificationSound.default` and document the limitation.
- Consider pairing with a `UIAlertController` if the app is foregrounded when the threshold is crossed.

---

## 6. Distance Calculation

Use `CLLocation(latitude:longitude:).distance(from:)` which returns metres along the Earth's surface (Haversine). This is accurate enough for the distances involved (300m–5km).

---

## Known Limitations Summary

| Scenario | Expected Behaviour |
|----------|--------------------|
| App backgrounded, "Always" permission granted | Alert fires via geofence (planned) |
| App backgrounded, only "When In Use" granted | Alert may not fire |
| App force-quit, region monitoring active | iOS may relaunch app and deliver alert |
| Underground / poor GPS | Alert may be delayed or missed |
| Silent mode / DND | Notification sound may be suppressed |
| User passes near stop without alighting | Alert fires anyway — no transit awareness |
