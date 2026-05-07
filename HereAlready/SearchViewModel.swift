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

    var hasSelectedDestination: Bool { selectedMapItem != nil }

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

    func clearDestination() {
        selectedMapItem = nil
        searchText = ""
        searchResults = []
    }
}
