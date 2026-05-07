import SwiftUI
import MapKit

struct RecentSearch: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let subtitle: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText = "" {
        didSet { scheduleSearch() }
    }
    @Published var isFocused = false
    @Published var searchResults: [MKMapItem] = []
    @Published var selectedMapItem: MKMapItem?
    @Published private(set) var recentSearches: [RecentSearch] = []

    var hasSelectedDestination: Bool { selectedMapItem != nil }

    private var searchTask: Task<Void, Never>?
    private let recentSearchesKey = "recentSearches"
    private let maxRecentSearches = 10

    init() {
        loadRecentSearches()
    }

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
        saveToRecentSearches(item)
    }

    func selectRecentSearch(_ recent: RecentSearch) {
        // Reconstruct a minimal MKMapItem from the stored coordinate
        let placemark = MKPlacemark(coordinate: recent.coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = recent.name
        selectedMapItem = item
        searchText = recent.name
        isFocused = false
        searchResults = []
        // Bring to front without duplicating
        saveToRecentSearches(item)
    }

    func clearDestination() {
        selectedMapItem = nil
        searchText = ""
        searchResults = []
    }

    // MARK: - Recent Searches Persistence

    private func saveToRecentSearches(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        guard CLLocationCoordinate2DIsValid(coordinate) else { return }
        let entry = RecentSearch(
            id: UUID(),
            name: item.name ?? "Unknown",
            subtitle: item.placemark.title ?? "",
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        // Remove any existing entry with same name+coordinate to avoid duplicates
        var updated = recentSearches.filter {
            !($0.name == entry.name && abs($0.latitude - entry.latitude) < 0.0001)
        }
        updated.insert(entry, at: 0)
        recentSearches = Array(updated.prefix(maxRecentSearches))
        persistRecentSearches()
    }

    private func persistRecentSearches() {
        guard let data = try? JSONEncoder().encode(recentSearches) else { return }
        UserDefaults.standard.set(data, forKey: recentSearchesKey)
    }

    private func loadRecentSearches() {
        guard let data = UserDefaults.standard.data(forKey: recentSearchesKey),
              let decoded = try? JSONDecoder().decode([RecentSearch].self, from: data) else { return }
        recentSearches = decoded
    }
}
