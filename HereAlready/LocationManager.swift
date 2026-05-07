import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    /// Full CLLocation (not just coordinate) so accuracy can be checked by TripMonitor.
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
        manager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
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
        print("LocationManager: Monitoring region '\(identifier)' at radius \(Int(radius))m")
    }

    func stopMonitoringAllRegions() {
        manager.monitoredRegions.forEach { manager.stopMonitoring(for: $0) }
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
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastKnownLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("LocationManager: Entered region \(region.identifier)")
        regionEnteredPublisher.send(region)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("LocationManager: Region monitoring failed — \(error.localizedDescription)")
    }
}
