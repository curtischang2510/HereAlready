# Testing: HereAlready

## Current State

The test targets exist (`HereAlreadyTests`, `HereAlreadyUITests`) but contain only the Xcode-generated placeholder. No meaningful tests have been written yet.

---

## Testing Strategy

### Unit Tests (`HereAlreadyTests`)

Preferred framework: Swift Testing (`@Test`, `#expect`) — already imported in the generated file.

#### Priority targets

**`SearchViewModel`**
- `displayItems` returns empty when `searchText` is empty and `recent` is empty.
- `displayItems` filters case-insensitively on `searchText`.
- `selectPlace(_:)` sets `searchText` and sets `isFocused = false`.

**Distance calculation (future `TripMonitor`)**
- Distance between two known coordinates returns the expected value within ±5m tolerance.
- `hasAlerted` flag prevents duplicate alert triggers.
- Stopping a trip resets `hasAlerted`.

**`LocationManager`**
- Difficult to unit test directly due to `CLLocationManager` dependency. Introduce a `LocationProviding` protocol to allow injection of a mock in tests.

---

### Integration / Simulator Tests

Use Xcode's location simulation (Debug → Simulate Location) to:
- Verify the map camera follows the simulated user location.
- Verify `LocationManager.lastKnownLocation` updates as the simulated position moves.
- Verify an alert fires when the simulated position enters the destination threshold.

These are manual tests until UI automation is added.

---

### UI Tests (`HereAlreadyUITests`)

Defer until core logic is stable. Minimal useful UI tests:
- App launches without crash.
- Search field is visible and accepts input.
- Tapping a search result dismisses the keyboard and collapses the panel.

---

## Running Tests

```bash
# From the project root (requires Xcode Command Line Tools)
xcodebuild test \
  -workspace HereAlready.xcworkspace \
  -scheme HereAlready \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'
```

---

## What NOT to Mock

- `CLLocationManager` should eventually be wrapped behind a protocol so tests do not require a real device or simulate system behaviour.
- `UNUserNotificationCenter` — use the real scheduler in integration tests; mock only in unit tests for `TripMonitor` alert logic.

---

## Proposed First Tests to Write

Before implementing Phase 2 (trip monitoring), write these tests first:

1. `SearchViewModelTests.swift`
   - Filter logic
   - Select place side effects

2. `TripMonitorTests.swift` (once `TripMonitor` is created)
   - Distance threshold comparison
   - Alert deduplication
   - Reset on new trip
