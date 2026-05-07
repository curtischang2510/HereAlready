# HereAlready MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a working iOS app that monitors the user's location and alerts them when they are within a configurable distance of a selected destination, including when the app is backgrounded.

**Architecture:** `AppContainer` owns `LocationManager` and `TripMonitor` at app scope, both injected via SwiftUI `.environmentObject`. `TripMonitor` subscribes to `LocationManager` via Combine and manages the full trip lifecycle — start, distance checking, geofence registration, alert firing, and deduplication. `SearchViewModel` uses `MKLocalSearch` for real place autocomplete.

**Tech Stack:** SwiftUI, MapKit (replaces Google Maps), CoreLocation, Combine, UserNotifications, Swift Testing

---

## Assumptions & Decisions Recorded

- **Switching to MapKit** (replacing Google Maps SDK). Removes CocoaPods, API key, and AppDelegate boilerplate. `MKLocalSearch` is sufficient for MVP destination search. Document in `docs/DECISIONS.md`.
- **Geofencing** (`CLCircularRegion`) is the primary background alert mechanism (already decided).
- Minimum threshold is 300m — acceptable given geofencing accuracy of ~100–200m.

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| DELETE | `HereAlready/AppDelegate.swift` | No longer needed (Google Maps init removed) |
| MODIFY | `Podfile` | Remove Google Maps pods |
| REWRITE | `HereAlready/Map.swift` | SwiftUI MapKit map with UserAnnotation + destination marker |
| MODIFY | `HereAlready/HereAlreadyApp.swift` | Use AppContainer, inject env objects |
| MODIFY | `HereAlready/ContentView.swift` | Reference `MapView` (renamed), pass env |
| MODIFY | `HereAlready/LocationManager.swift` | Publish `CLLocation`, add geofencing + `regionEnteredPublisher` |
| CREATE | `HereAlready/AppContainer.swift` | Owns LocationManager + TripMonitor |
| CREATE | `HereAlready/TripMonitor.swift` | Trip lifecycle, distance logic, alert dedup, geofence |
| MODIFY | `HereAlready/SearchViewModel.swift` | MKLocalSearch, store `MKMapItem` |
| MODIFY | `HereAlready/SearchPage.swift` | Real results list, threshold picker, start/stop button, distance display |
| MODIFY | `HereAlready/Info.plist` | Background modes, improved usage strings |
| CREATE | `HereAlreadyTests/SearchViewModelTests.swift` | Unit tests for search logic |
| CREATE | `HereAlreadyTests/TripMonitorTests.swift` | Unit tests for trip logic |

---

## Task 1: MapKit Migration — Remove Google Maps

**Files:**
- Modify: `Podfile`
- Delete: `HereAlready/AppDelegate.swift`
- Rewrite: `HereAlready/Map.swift`
- Modify: `HereAlready/HereAlreadyApp.swift`
- Modify: `HereAlready/ContentView.swift`

- [ ] **Step 1.1: Update Podfile to remove Google Maps**

Replace the entire contents of `Podfile` with:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '18.3'

target 'HereAlready' do
  use_frameworks!
  # No external pods — using system frameworks only (MapKit, CoreLocation)
end
```

- [ ] **Step 1.2: Run pod install to clean up Pods**

```bash
cd /Users/curtischang/Documents/Projects/HereAlready
pod install
```

Expected: "Pod installation complete! There are 0 dependencies from the Podfile."

- [ ] **Step 1.3: Rewrite Map.swift with MapKit**

Replace the entire contents of `HereAlready/Map.swift` with:

```swift
import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var tripMonitor: TripMonitor
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            if let destination = tripMonitor.destination {
                Marker("Destination", coordinate: destination)
                    .tint(.red)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .ignoresSafeArea()
    }
}
```

- [ ] **Step 1.4: Delete AppDelegate.swift**

Delete `HereAlready/AppDelegate.swift` from the Xcode project (right-click → Delete → Move to Trash).

- [ ] **Step 1.5: Update HereAlreadyApp.swift — remove AppDelegate adaptor**

Replace the entire contents of `HereAlready/HereAlreadyApp.swift`:

```swift
import SwiftUI

@main
struct HereAlreadyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

- [ ] **Step 1.6: Update ContentView.swift — use MapView**

In `HereAlready/ContentView.swift`, change the line `Map()` to `MapView()`.

The full file should read:

```swift
import SwiftUI

struct ContentView: View {
    @StateObject var sharedSearchViewModel = SearchViewModel()

    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let bottomSafeArea = geometry.safeAreaInsets.bottom
            let expandedYOffset = screenHeight * 0.05
            let collapsedYOffset = screenHeight - 100

            _SlidingPanelView(
                sharedSearchViewModel: sharedSearchViewModel,
                expandedYOffset: expandedYOffset,
                collapsedYOffset: collapsedYOffset,
                screenHeight: screenHeight,
                bottomSafeArea: bottomSafeArea
            )
        }
        .edgesIgnoringSafeArea(.all)
    }
}

fileprivate struct _SlidingPanelView: View {
    @ObservedObject var sharedSearchViewModel: SearchViewModel
    let expandedYOffset: CGFloat
    let collapsedYOffset: CGFloat
    let screenHeight: CGFloat
    let bottomSafeArea: CGFloat

    @State private var currentYOffset: CGFloat

    init(sharedSearchViewModel: SearchViewModel, expandedYOffset: CGFloat, collapsedYOffset: CGFloat, screenHeight: CGFloat, bottomSafeArea: CGFloat) {
        self.sharedSearchViewModel = sharedSearchViewModel
        self.expandedYOffset = expandedYOffset
        self.collapsedYOffset = collapsedYOffset
        self.screenHeight = screenHeight
        self.bottomSafeArea = bottomSafeArea
        _currentYOffset = State(initialValue: sharedSearchViewModel.isFocused ? expandedYOffset : collapsedYOffset)
    }

    var body: some View {
        ZStack(alignment: .top) {
            MapView()
                .edgesIgnoringSafeArea(.all)

            SearchPage(viewModel: sharedSearchViewModel)
                .frame(height: screenHeight - expandedYOffset + bottomSafeArea)
                .offset(y: currentYOffset)
        }
        .onChange(of: sharedSearchViewModel.isFocused) { _, isFocused in
            withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.75, blendDuration: 0.3)) {
                currentYOffset = isFocused ? expandedYOffset : collapsedYOffset
            }
        }
    }
}
```

- [ ] **Step 1.7: Build and verify the app compiles**

Open `HereAlready.xcworkspace` in Xcode → Product → Build (⌘B).

Expected: 0 errors. The map should display using MapKit. AppDelegate and all Google Maps references are gone.

- [ ] **Step 1.8: Commit**

```bash
git add HereAlready/Map.swift HereAlready/HereAlreadyApp.swift HereAlready/ContentView.swift Podfile Podfile.lock
git rm HereAlready/AppDelegate.swift
git commit -m "feat: replace Google Maps SDK with MapKit

Removes CocoaPods dependency, API key, and AppDelegate boilerplate.
MKLocalSearch will replace Google Places for destination search."
```

---

## Task 2: AppContainer + Dependency Injection

**Files:**
- Create: `HereAlready/AppContainer.swift`
- Modify: `HereAlready/HereAlreadyApp.swift`
- Modify: `HereAlready/ContentView.swift`
- Modify: `HereAlready/Map.swift`

- [ ] **Step 2.1: Create AppContainer.swift**

Create `HereAlready/AppContainer.swift`:

```swift
import Foundation

/// Owns app-level services and wires their dependencies.
/// Injected into the SwiftUI environment so any view can access LocationManager or TripMonitor.
class AppContainer: ObservableObject {
    let locationManager = LocationManager()
    lazy var tripMonitor: TripMonitor = TripMonitor(locationManager: locationManager)
}
```

- [ ] **Step 2.2: Update HereAlreadyApp.swift to inject environment objects**

Replace the contents of `HereAlready/HereAlreadyApp.swift`:

```swift
import SwiftUI

@main
struct HereAlreadyApp: App {
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container.locationManager)
                .environmentObject(container.tripMonitor)
        }
    }
}
```

- [ ] **Step 2.3: Remove the local LocationManager from Map.swift**

`MapView` will now read LocationManager and TripMonitor from the environment (already written in Task 1 Step 1.3). Verify the `@EnvironmentObject` declarations are present — no changes needed.

- [ ] **Step 2.4: Build to verify**

Product → Build (⌘B). Expected: 0 errors. The `@EnvironmentObject` will cause a runtime crash if the environment objects aren't provided, but since `HereAlreadyApp` injects both, this is fine.

- [ ] **Step 2.5: Commit**

```bash
git add HereAlready/AppContainer.swift HereAlready/HereAlreadyApp.swift
git commit -m "feat: add AppContainer for app-level dependency injection

LocationManager and TripMonitor are now app-scoped and injected
via SwiftUI environmentObject, not owned by individual views."
```

---

## Task 3: Update LocationManager

**Files:**
- Modify: `HereAlready/LocationManager.swift`

LocationManager needs three additions before TripMonitor can use it:
1. Publish `CLLocation` (not just `CLLocationCoordinate2D`) so `TripMonitor` can check `horizontalAccuracy`.
2. A `PassthroughSubject` that fires when a monitored geofence region is entered.
3. Methods to start and stop geofence region monitoring.

- [ ] **Step 3.1: Replace LocationManager.swift**

```swift
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    /// Most recent location update. Includes accuracy info for filtering.
    @Published var lastKnownLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?

    /// Fires when the device enters a monitored CLCircularRegion.
    let regionEnteredPublisher = PassthroughSubject<CLRegion, Never>()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 20
        requestLocation()
    }

    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else { return }
        print("LocationManager: Starting location updates")
        manager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        print("LocationManager: Stopping location updates")
        manager.stopUpdatingLocation()
    }

    func requestAlwaysAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    func startMonitoringRegion(center: CLLocationCoordinate2D, radius: Double, identifier: String) {
        let region = CLCircularRegion(center: center, radius: radius, identifier: identifier)
        region.notifyOnEntry = true
        region.notifyOnExit = false
        manager.startMonitoring(for: region)
        print("LocationManager: Monitoring region '\(identifier)' radius \(radius)m")
    }

    func stopMonitoringAllRegions() {
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        print("LocationManager: Stopped all region monitoring")
    }

    private func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            self.authorizationStatus = manager.authorizationStatus
        case .authorizedWhenInUse, .authorizedAlways:
            self.authorizationStatus = manager.authorizationStatus
            manager.requestLocation()
        @unknown default:
            break
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        print("LocationManager: Authorization changed to \(manager.authorizationStatus.rawValue)")
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastKnownLocation = location
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("LocationManager: Entered region \(region.identifier)")
        regionEnteredPublisher.send(region)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager: Failed — \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("LocationManager: Region monitoring failed — \(error.localizedDescription)")
    }
}
```

- [ ] **Step 3.2: Build to verify**

Product → Build (⌘B). Expected: 0 errors.

- [ ] **Step 3.3: Commit**

```bash
git add HereAlready/LocationManager.swift
git commit -m "feat: update LocationManager with CLLocation publishing and geofencing

Publishes CLLocation (not just coordinate) for accuracy filtering.
Adds startMonitoringRegion/stopMonitoringAllRegions and regionEnteredPublisher
for TripMonitor to subscribe to."
```

---

## Task 4: Write SearchViewModel Tests (TDD)

**Files:**
- Create: `HereAlreadyTests/SearchViewModelTests.swift`

Write tests first. They will fail because `SearchViewModel` still has the old API.

- [ ] **Step 4.1: Create SearchViewModelTests.swift**

```swift
import Testing
import MapKit
@testable import HereAlready

@MainActor
struct SearchViewModelTests {

    @Test("Search text empty → display items empty")
    func emptySearchYieldsNoResults() {
        let vm = SearchViewModel()
        vm.searchText = ""
        #expect(vm.searchResults.isEmpty)
    }

    @Test("Selecting a place stores the MKMapItem and collapses panel")
    func selectPlaceStoresItemAndUnfocuses() {
        let vm = SearchViewModel()
        vm.isFocused = true

        let coordinate = CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198)
        let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        item.name = "Raffles Place MRT"

        vm.selectPlace(item)

        #expect(vm.selectedMapItem === item)
        #expect(vm.searchText == "Raffles Place MRT")
        #expect(!vm.isFocused)
        #expect(vm.searchResults.isEmpty)
    }

    @Test("Selecting a place exposes its coordinate")
    func selectPlaceExposesCoordinate() {
        let vm = SearchViewModel()
        let coordinate = CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198)
        let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        item.name = "Raffles Place MRT"

        vm.selectPlace(item)

        #expect(abs((vm.selectedMapItem?.placemark.coordinate.latitude ?? 0) - 1.3521) < 0.0001)
        #expect(abs((vm.selectedMapItem?.placemark.coordinate.longitude ?? 0) - 103.8198) < 0.0001)
    }
}
```

- [ ] **Step 4.2: Run tests to confirm they fail**

In Xcode: Product → Test (⌘U), or run:

```bash
xcodebuild test \
  -workspace HereAlready.xcworkspace \
  -scheme HereAlready \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -only-testing:HereAlreadyTests/SearchViewModelTests 2>&1 | tail -20
```

Expected: Tests fail — `searchResults` property doesn't exist yet; `selectPlace` takes a `String` not `MKMapItem`.

---

## Task 5: Implement Real Place Search

**Files:**
- Modify: `HereAlready/SearchViewModel.swift`

- [ ] **Step 5.1: Replace SearchViewModel.swift**

```swift
import SwiftUI
import MapKit

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText = "" {
        didSet { scheduleSearch() }
    }
    @Published var isFocused = false
    @Published var searchResults: [MKMapItem] = []
    @Published var selectedMapItem: MKMapItem?

    private var searchTask: Task<Void, Never>?

    private func scheduleSearch() {
        searchTask?.cancel()
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await performSearch()
        }
    }

    private func performSearch() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        guard let response = try? await MKLocalSearch(request: request).start() else { return }
        searchResults = response.mapItems
    }

    func selectPlace(_ item: MKMapItem) {
        selectedMapItem = item
        searchText = item.name ?? ""
        isFocused = false
        searchResults = []
    }
}
```

- [ ] **Step 5.2: Run SearchViewModel tests to confirm they pass**

```bash
xcodebuild test \
  -workspace HereAlready.xcworkspace \
  -scheme HereAlready \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -only-testing:HereAlreadyTests/SearchViewModelTests 2>&1 | tail -20
```

Expected: All 3 tests PASS.

- [ ] **Step 5.3: Commit**

```bash
git add HereAlready/SearchViewModel.swift HereAlreadyTests/SearchViewModelTests.swift
git commit -m "feat: replace hardcoded search with MKLocalSearch

SearchViewModel now uses MKLocalSearch with 300ms debounce.
selectPlace stores MKMapItem including coordinate for TripMonitor."
```

---

## Task 6: Update SearchPage for Real Results

**Files:**
- Modify: `HereAlready/SearchPage.swift`

`SearchPage` currently renders `[String]`. It must now render `[MKMapItem]`.

- [ ] **Step 6.1: Replace SearchPage.swift**

```swift
import SwiftUI
import MapKit

struct SearchPage: View {
    @StateObject var searchViewModel: SearchViewModel
    @FocusState private var textFieldIsFocused: Bool

    init(viewModel: SearchViewModel = SearchViewModel()) {
        _searchViewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Where do you want to go?", text: $searchViewModel.searchText)
                .padding()
                .textFieldStyle(.roundedBorder)
                .focused($textFieldIsFocused)

            if searchViewModel.isFocused {
                if !searchViewModel.searchResults.isEmpty {
                    List(searchViewModel.searchResults, id: \.self) { item in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name ?? "Unknown place")
                                .font(.body)
                            if let subtitle = item.placemark.title, !subtitle.isEmpty {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            searchViewModel.selectPlace(item)
                        }
                    }
                    .listStyle(.plain)
                    .frame(maxHeight: 280)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                } else if !searchViewModel.searchText.isEmpty {
                    Text("No results found")
                        .padding()
                        .foregroundColor(.gray)
                }
            }

            Spacer()
        }
        .background(Material.regular)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.vertical)
        .onChange(of: searchViewModel.isFocused) { _, newValue in
            if textFieldIsFocused != newValue { textFieldIsFocused = newValue }
        }
        .onChange(of: textFieldIsFocused) { _, newValue in
            if searchViewModel.isFocused != newValue { searchViewModel.isFocused = newValue }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if searchViewModel.isFocused { searchViewModel.isFocused = false }
        }
    }
}
```

- [ ] **Step 6.2: Build and manually verify in simulator**

Product → Run (⌘R). Type a place name in the search field. Confirm real results appear from MKLocalSearch.

- [ ] **Step 6.3: Commit**

```bash
git add HereAlready/SearchPage.swift
git commit -m "feat: update SearchPage to display MKMapItem results

Results now show place name and address subtitle.
Tapping a result stores the MKMapItem coordinate for trip monitoring."
```

---

## Task 7: Write TripMonitor Tests (TDD)

**Files:**
- Create: `HereAlreadyTests/TripMonitorTests.swift`

Write tests first — they will fail because `TripMonitor` doesn't exist yet.

- [ ] **Step 7.1: Create TripMonitorTests.swift**

```swift
import Testing
import CoreLocation
@testable import HereAlready

@MainActor
struct TripMonitorTests {

    func makeTripMonitor() -> TripMonitor {
        TripMonitor(locationManager: LocationManager())
    }

    @Test("Trip monitor is inactive by default")
    func inactiveByDefault() {
        let tm = makeTripMonitor()
        #expect(!tm.isActive)
        #expect(tm.distanceToDestination == nil)
        #expect(tm.destination == nil)
    }

    @Test("start() sets isActive and destination")
    func startSetsActiveState() {
        let tm = makeTripMonitor()
        let dest = CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198)
        tm.start(destination: dest, thresholdMetres: 500)
        #expect(tm.isActive)
        #expect(tm.destination != nil)
    }

    @Test("stop() clears all state")
    func stopClearsState() {
        let tm = makeTripMonitor()
        let dest = CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198)
        tm.start(destination: dest, thresholdMetres: 500)
        tm.stop()
        #expect(!tm.isActive)
        #expect(tm.destination == nil)
        #expect(tm.distanceToDestination == nil)
    }

    @Test("update() computes distance to destination")
    func updateComputesDistance() {
        let tm = makeTripMonitor()
        let dest = CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198)
        tm.start(destination: dest, thresholdMetres: 500)

        // User is exactly at destination
        let userLocation = CLLocation(latitude: 1.3521, longitude: 103.8198)
        tm.update(location: userLocation)

        #expect(tm.distanceToDestination != nil)
        #expect(tm.distanceToDestination! < 1.0) // ~0m
    }

    @Test("alert fires once when within threshold")
    func alertFiresOnceWhenWithinThreshold() {
        let tm = makeTripMonitor()
        let dest = CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198)
        tm.start(destination: dest, thresholdMetres: 500)

        let nearby = CLLocation(latitude: 1.3521, longitude: 103.8198) // at destination, distance = 0
        tm.update(location: nearby)
        tm.update(location: nearby) // second call — should not fire again

        #expect(tm.alertFiredCount == 1)
    }

    @Test("alert does not fire when beyond threshold")
    func alertDoesNotFireBeyondThreshold() {
        let tm = makeTripMonitor()
        let dest = CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198)
        tm.start(destination: dest, thresholdMetres: 300)

        // ~1km away
        let farAway = CLLocation(latitude: 1.3611, longitude: 103.8198)
        tm.update(location: farAway)

        #expect(tm.alertFiredCount == 0)
    }

    @Test("new trip resets alert so it can fire again")
    func newTripResetsAlert() {
        let tm = makeTripMonitor()
        let dest = CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198)

        // First trip — alert fires
        tm.start(destination: dest, thresholdMetres: 500)
        tm.update(location: CLLocation(latitude: 1.3521, longitude: 103.8198))
        #expect(tm.alertFiredCount == 1)

        // Second trip — alert should fire again
        tm.stop()
        tm.start(destination: dest, thresholdMetres: 500)
        tm.update(location: CLLocation(latitude: 1.3521, longitude: 103.8198))
        #expect(tm.alertFiredCount == 2)
    }

    @Test("inaccurate GPS updates are ignored")
    func inaccurateUpdateIgnored() {
        let tm = makeTripMonitor()
        let dest = CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198)
        tm.start(destination: dest, thresholdMetres: 500)

        // horizontalAccuracy > 100 → should be filtered out
        let inaccurate = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198),
            altitude: 0,
            horizontalAccuracy: 200, // too inaccurate
            verticalAccuracy: 0,
            timestamp: Date()
        )
        tm.update(location: inaccurate)

        #expect(tm.alertFiredCount == 0)
        #expect(tm.distanceToDestination == nil)
    }
}
```

- [ ] **Step 7.2: Run tests to confirm they fail**

```bash
xcodebuild test \
  -workspace HereAlready.xcworkspace \
  -scheme HereAlready \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -only-testing:HereAlreadyTests/TripMonitorTests 2>&1 | tail -20
```

Expected: Build error — `TripMonitor` type does not exist yet.

---

## Task 8: Implement TripMonitor

**Files:**
- Create: `HereAlready/TripMonitor.swift`

- [ ] **Step 8.1: Create TripMonitor.swift**

```swift
import CoreLocation
import Combine
import UserNotifications

@MainActor
class TripMonitor: ObservableObject {
    @Published var isActive = false
    @Published var distanceToDestination: Double?

    /// Exposed for testing deduplication. Not used in UI.
    private(set) var alertFiredCount = 0
    private(set) var destination: CLLocationCoordinate2D?

    private var thresholdMetres: Double = 500
    private var hasAlerted = false

    private let locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()

    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        locationManager.$lastKnownLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.update(location: location)
            }
            .store(in: &cancellables)

        locationManager.regionEnteredPublisher
            .sink { [weak self] _ in
                self?.fireAlert()
            }
            .store(in: &cancellables)
    }

    func start(destination: CLLocationCoordinate2D, thresholdMetres: Double) {
        self.destination = destination
        self.thresholdMetres = thresholdMetres
        self.hasAlerted = false
        self.isActive = true
        locationManager.startMonitoringRegion(
            center: destination,
            radius: thresholdMetres,
            identifier: "trip-destination"
        )
        requestNotificationPermission()
    }

    func stop() {
        isActive = false
        destination = nil
        distanceToDestination = nil
        hasAlerted = false
        locationManager.stopMonitoringAllRegions()
    }

    /// Called by tests directly or by Combine subscription.
    func update(location: CLLocation) {
        guard isActive, let dest = destination else { return }
        // Ignore readings with poor accuracy (e.g. underground, signal loss)
        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 100 else { return }

        let destLocation = CLLocation(latitude: dest.latitude, longitude: dest.longitude)
        let distance = location.distance(from: destLocation)
        distanceToDestination = distance

        if distance <= thresholdMetres {
            fireAlert()
        }
    }

    func fireAlert() {
        guard !hasAlerted else { return }
        hasAlerted = true
        alertFiredCount += 1
        scheduleNotification()
    }

    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "You're almost there!"
        content.body = "You're within \(Int(thresholdMetres))m of your destination. Time to wake up!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "trip-arrival",
            content: content,
            trigger: nil // deliver immediately
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("TripMonitor: Notification error — \(error)") }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            print("TripMonitor: Notification permission granted: \(granted)")
        }
    }
}
```

- [ ] **Step 8.2: Run TripMonitor tests to confirm they pass**

```bash
xcodebuild test \
  -workspace HereAlready.xcworkspace \
  -scheme HereAlready \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -only-testing:HereAlreadyTests/TripMonitorTests 2>&1 | tail -20
```

Expected: All 7 tests PASS.

- [ ] **Step 8.3: Commit**

```bash
git add HereAlready/TripMonitor.swift HereAlreadyTests/TripMonitorTests.swift
git commit -m "feat: implement TripMonitor with distance checking and alert dedup

Subscribes to LocationManager via Combine. Filters inaccurate GPS (<= 100m accuracy).
Fires a local notification once per trip. Registers CLCircularRegion for background."
```

---

## Task 9: Trip Configuration UI

**Files:**
- Modify: `HereAlready/SearchPage.swift`

Add threshold picker, start/stop button, and live distance display to `SearchPage`.

- [ ] **Step 9.1: Update SearchPage.swift to add trip controls**

Replace the contents of `HereAlready/SearchPage.swift`:

```swift
import SwiftUI
import MapKit

struct SearchPage: View {
    @StateObject var searchViewModel: SearchViewModel
    @EnvironmentObject var tripMonitor: TripMonitor
    @FocusState private var textFieldIsFocused: Bool
    @State private var selectedThreshold: Double = 500

    let thresholds: [(label: String, value: Double)] = [
        ("300m", 300), ("500m", 500), ("1km", 1000)
    ]

    init(viewModel: SearchViewModel = SearchViewModel()) {
        _searchViewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            TextField("Where do you want to go?", text: $searchViewModel.searchText)
                .padding()
                .textFieldStyle(.roundedBorder)
                .focused($textFieldIsFocused)

            // Search results
            if searchViewModel.isFocused {
                if !searchViewModel.searchResults.isEmpty {
                    List(searchViewModel.searchResults, id: \.self) { item in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name ?? "Unknown place")
                                .font(.body)
                            if let subtitle = item.placemark.title, !subtitle.isEmpty {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture { searchViewModel.selectPlace(item) }
                    }
                    .listStyle(.plain)
                    .frame(maxHeight: 280)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                } else if !searchViewModel.searchText.isEmpty {
                    Text("No results found")
                        .padding()
                        .foregroundColor(.gray)
                }
            }

            // Trip controls — only when a destination is selected and not searching
            if !searchViewModel.isFocused, searchViewModel.selectedMapItem != nil || tripMonitor.isActive {
                Divider().padding(.horizontal)

                VStack(spacing: 12) {
                    // Threshold picker
                    if !tripMonitor.isActive {
                        Picker("Alert distance", selection: $selectedThreshold) {
                            ForEach(thresholds, id: \.value) { option in
                                Text(option.label).tag(option.value)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                    }

                    // Distance display while active
                    if tripMonitor.isActive, let distance = tripMonitor.distanceToDestination {
                        Text(formattedDistance(distance))
                            .font(.headline)
                            .foregroundColor(distance <= selectedThreshold ? .green : .primary)
                    }

                    // Start / Stop button
                    Button {
                        if tripMonitor.isActive {
                            tripMonitor.stop()
                        } else if let item = searchViewModel.selectedMapItem {
                            tripMonitor.start(
                                destination: item.placemark.coordinate,
                                thresholdMetres: selectedThreshold
                            )
                        }
                    } label: {
                        Text(tripMonitor.isActive ? "Stop Alert" : "Start Alert")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(tripMonitor.isActive ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
            }

            Spacer()
        }
        .background(Material.regular)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.vertical)
        .onChange(of: searchViewModel.isFocused) { _, newValue in
            if textFieldIsFocused != newValue { textFieldIsFocused = newValue }
        }
        .onChange(of: textFieldIsFocused) { _, newValue in
            if searchViewModel.isFocused != newValue { searchViewModel.isFocused = newValue }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if searchViewModel.isFocused { searchViewModel.isFocused = false }
        }
    }

    private func formattedDistance(_ metres: Double) -> String {
        if metres >= 1000 {
            return String(format: "%.1f km to destination", metres / 1000)
        } else {
            return "\(Int(metres))m to destination"
        }
    }
}
```

- [ ] **Step 9.2: Build and manually test in simulator**

Product → Run (⌘R).
1. Search for a place and tap a result.
2. Confirm the threshold picker and "Start Alert" button appear.
3. Tap "Start Alert" — confirm it changes to "Stop Alert".
4. Use Xcode's location simulator (Debug → Simulate Location → Custom Location) to move near the destination.
5. Confirm the distance display updates.

- [ ] **Step 9.3: Commit**

```bash
git add HereAlready/SearchPage.swift
git commit -m "feat: add trip configuration UI to SearchPage

Adds threshold picker (300m/500m/1km), Start/Stop button, and live
distance display. Controls appear after a destination is selected."
```

---

## Task 10: Background Geofencing + Info.plist

**Files:**
- Modify: `HereAlready/Info.plist`

- [ ] **Step 10.1: Update Info.plist with background modes and improved strings**

Replace the entire contents of `HereAlready/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>HereAlready shows your location on the map and calculates your distance to your destination.</string>
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>HereAlready needs background location to alert you when you're approaching your destination, even if the app is not open.</string>
    <key>UIBackgroundModes</key>
    <array>
        <string>location</string>
    </array>
</dict>
</plist>
```

- [ ] **Step 10.2: Request Always authorization when trip starts**

In `HereAlready/TripMonitor.swift`, add a call to `locationManager.requestAlwaysAuthorization()` inside the `start()` method, after `requestNotificationPermission()`:

```swift
func start(destination: CLLocationCoordinate2D, thresholdMetres: Double) {
    self.destination = destination
    self.thresholdMetres = thresholdMetres
    self.hasAlerted = false
    self.isActive = true
    locationManager.startMonitoringRegion(
        center: destination,
        radius: thresholdMetres,
        identifier: "trip-destination"
    )
    requestNotificationPermission()
    locationManager.requestAlwaysAuthorization() // needed for background geofencing
}
```

- [ ] **Step 10.3: Test background alert on a real device**

Simulator cannot reliably test geofence entry. On a real device:
1. Set a destination near your current location.
2. Tap "Start Alert".
3. Lock the screen.
4. Walk toward the destination.
5. Confirm a notification appears.

- [ ] **Step 10.4: Commit**

```bash
git add HereAlready/Info.plist HereAlready/TripMonitor.swift
git commit -m "feat: enable background geofencing for location alerts

Adds UIBackgroundModes:location to Info.plist. Requests Always authorization
on trip start so CLCircularRegion monitoring works when app is backgrounded."
```

---

## Task 11: Permission Denial UI

**Files:**
- Modify: `HereAlready/ContentView.swift`

Show a blocking message when location permission is denied.

- [ ] **Step 11.1: Add permission denied overlay to ContentView.swift**

Add a denied state overlay inside `_SlidingPanelView`. Replace the `body` property in `_SlidingPanelView`:

```swift
var body: some View {
    ZStack(alignment: .top) {
        MapView()
            .edgesIgnoringSafeArea(.all)

        SearchPage(viewModel: sharedSearchViewModel)
            .frame(height: screenHeight - expandedYOffset + bottomSafeArea)
            .offset(y: currentYOffset)
    }
    .onChange(of: sharedSearchViewModel.isFocused) { _, isFocused in
        withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.75, blendDuration: 0.3)) {
            currentYOffset = isFocused ? expandedYOffset : collapsedYOffset
        }
    }
    .overlay {
        LocationDeniedView()
    }
}
```

- [ ] **Step 11.2: Create LocationDeniedView as a private struct in ContentView.swift**

Add after the `_SlidingPanelView` struct, still inside ContentView.swift:

```swift
private struct LocationDeniedView: View {
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
            ZStack {
                Color.black.opacity(0.7).ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "location.slash.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                    Text("Location Access Required")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                    Text("HereAlready needs your location to alert you before you miss your stop.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 32)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }
}
```

- [ ] **Step 11.3: Build and verify**

Product → Build (⌘B). To test the denied state, reset the simulator's location permissions: Simulator → Device → Privacy & Security → Location Services, or reset all settings.

- [ ] **Step 11.4: Run all tests**

```bash
xcodebuild test \
  -workspace HereAlready.xcworkspace \
  -scheme HereAlready \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' 2>&1 | tail -30
```

Expected: All tests pass.

- [ ] **Step 11.5: Commit**

```bash
git add HereAlready/ContentView.swift
git commit -m "feat: show permission denied overlay with Settings deep-link

Displays a blocking overlay when location access is denied or restricted,
with a button to open iOS Settings directly."
```

---

## Task 12: Update Docs

**Files:**
- Modify: `docs/DECISIONS.md`
- Modify: `docs/ARCHITECTURE.md`

- [ ] **Step 12.1: Close the MapKit decision in DECISIONS.md**

In `docs/DECISIONS.md`, update the MapKit decision status from "Undecided" to "Decided — using MapKit".

- [ ] **Step 12.2: Update ARCHITECTURE.md to reflect final implementation**

Update the "Missing / Not Yet Implemented" section in `docs/ARCHITECTURE.md` to reflect what has now been built.

- [ ] **Step 12.3: Final commit**

```bash
git add docs/DECISIONS.md docs/ARCHITECTURE.md
git commit -m "docs: update architecture and decisions for MapKit migration + MVP implementation"
```

---

## Self-Review

### Spec Coverage Check

| Requirement (from CLAUDE.md) | Covered By |
|-----------------------------|-----------|
| User can select a destination | Task 5, 6 — MKLocalSearch + MKMapItem stored |
| User can configure a distance threshold | Task 9 — threshold picker in SearchPage |
| App monitors location while trip active | Task 3 — LocationManager, Task 8 — TripMonitor.update() |
| App alerts when distance ≤ threshold | Task 8 — TripMonitor.fireAlert() + Task 10 — geofencing |
| No repeated duplicate alarms | Task 8 — `hasAlerted` flag, tested in Task 7 |
| Permission denial handled gracefully | Task 11 — LocationDeniedView |
| Avoid excessive battery drain | Task 10 — geofencing (not continuous GPS in background) |
| Background alerts | Task 10 — CLCircularRegion + UIBackgroundModes |

### Placeholder Scan

No TBD, TODO, or incomplete steps present.

### Type Consistency

- `LocationManager.lastKnownLocation: CLLocation?` — used as `CLLocation` in `TripMonitor.update(location: CLLocation)`. ✓
- `TripMonitor.destination: CLLocationCoordinate2D?` — exposed as `CLLocationCoordinate2D?` and read in `MapView` as `Marker("Destination", coordinate: destination)`. ✓
- `SearchViewModel.selectedMapItem: MKMapItem?` — read in `SearchPage` as `item.placemark.coordinate` passed to `TripMonitor.start(destination:thresholdMetres:)`. ✓
- `TripMonitor.alertFiredCount: Int` — incremented in `fireAlert()`, read in tests. ✓
