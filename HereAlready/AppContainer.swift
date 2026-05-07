import Foundation

/// Owns app-level services and wires their dependencies.
/// Injected into the SwiftUI environment so any view can access LocationManager or TripMonitor.
class AppContainer: ObservableObject {
    let locationManager = LocationManager()
    lazy var tripMonitor: TripMonitor = TripMonitor(locationManager: locationManager)
}
