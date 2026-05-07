import CoreLocation
import Combine
import UserNotifications

class TripMonitor: ObservableObject {
    @Published var isActive = false
    @Published var distanceToDestination: Double?
    @Published private(set) var destination: CLLocationCoordinate2D?

    /// Exposed for testing deduplication.
    private(set) var alertFiredCount = 0
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
            .receive(on: RunLoop.main)
            .sink { [weak self] location in
                self?.update(location: location)
            }
            .store(in: &cancellables)

        locationManager.regionEnteredPublisher
            .receive(on: RunLoop.main)
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
        locationManager.requestAlwaysAuthorization()
        requestNotificationPermission()
        // Seed distance immediately — Combine only fires on new events,
        // so if location hasn't changed since start we'd hang on "Calculating…"
        if let current = locationManager.lastKnownLocation {
            update(location: current)
        }
    }

    func stop() {
        isActive = false
        destination = nil
        distanceToDestination = nil
        hasAlerted = false
        locationManager.stopMonitoringAllRegions()
    }

    /// Called directly by Combine subscription or by tests.
    func update(location: CLLocation) {
        guard isActive, let dest = destination else { return }
        // Negative accuracy means invalid fix; large values are still usable for coarse trip alerts.
        guard location.horizontalAccuracy >= 0 else { return }

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
        content.title = "You're almost there! 🚐"
        content.body = "Within \(Int(thresholdMetres))m of your destination — time to wake up!"
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
            print("TripMonitor: Notification permission — \(granted ? "granted" : "denied")")
        }
    }
}
