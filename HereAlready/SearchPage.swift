import SwiftUI
import MapKit

struct SearchPage: View {
    @StateObject var searchViewModel: SearchViewModel
    @EnvironmentObject var tripMonitor: TripMonitor
    @FocusState private var textFieldIsFocused: Bool
    @State private var selectedThreshold: Double = 500

    init(viewModel: SearchViewModel) {
        _searchViewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            dragHandle

            if tripMonitor.isActive {
                activeTripView
            } else {
                searchField
                if searchViewModel.isFocused {
                    searchResultsList
                } else if searchViewModel.hasSelectedDestination {
                    destinationConfigView
                }
            }

            Spacer()
        }
        .background(Material.regular)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
        .padding(.vertical)
        .onChange(of: searchViewModel.isFocused) { _, newValue in
            if textFieldIsFocused != newValue { textFieldIsFocused = newValue }
        }
        .onChange(of: textFieldIsFocused) { _, newValue in
            if searchViewModel.isFocused != newValue { searchViewModel.isFocused = newValue }
        }
    }

    // MARK: - Drag Handle

    private var dragHandle: some View {
        Capsule()
            .fill(Color(.systemGray4))
            .frame(width: 36, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 8)
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(searchViewModel.hasSelectedDestination ? .blue : .gray)
                .font(.system(size: 16, weight: .medium))

            TextField("Where do you want to go?", text: $searchViewModel.searchText)
                .focused($textFieldIsFocused)

            if searchViewModel.hasSelectedDestination {
                Button {
                    searchViewModel.clearDestination()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color(.systemGray6))
        .cornerRadius(13)
        .padding(.horizontal, 16)
        .padding(.bottom, searchViewModel.isFocused || searchViewModel.hasSelectedDestination ? 8 : 12)
    }

    // MARK: - Search Results

    @ViewBuilder
    private var searchResultsList: some View {
        if !searchViewModel.searchResults.isEmpty {
            List(searchViewModel.searchResults, id: \.self) { item in
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red.opacity(0.7))
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name ?? "Unknown place")
                            .font(.body)
                        if let subtitle = item.placemark.title, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { searchViewModel.selectPlace(item) }
            }
            .listStyle(.plain)
            .frame(maxHeight: 260)
        } else if !searchViewModel.searchText.isEmpty {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Searching…")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
        }
    }

    // MARK: - Destination Config (destination selected, trip not started)

    @ViewBuilder
    private var destinationConfigView: some View {
        if let item = searchViewModel.selectedMapItem {
            VStack(spacing: 0) {
                Divider()
                    .padding(.horizontal, 16)

                // Destination summary
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(.red.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.red)
                            .font(.system(size: 16, weight: .medium))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name ?? "Destination")
                            .font(.headline)
                            .lineLimit(1)
                        if let subtitle = item.placemark.title, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Threshold picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Alert me when within:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)

                    Picker("Alert distance", selection: $selectedThreshold) {
                        Text("300m").tag(300.0)
                        Text("500m").tag(500.0)
                        Text("1 km").tag(1000.0)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 12)

                // Start button
                Button {
                    tripMonitor.start(
                        destination: item.placemark.coordinate,
                        thresholdMetres: selectedThreshold
                    )
                } label: {
                    Label("Start Alert", systemImage: "bell.badge.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.blue, Color(red: 0.1, green: 0.4, blue: 0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Active Trip View

    private var activeTripView: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.horizontal, 16)

            // Distance display
            if let distance = tripMonitor.distanceToDestination {
                VStack(spacing: 4) {
                    Text(formattedDistance(distance))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(distance <= selectedThreshold ? .green : .primary)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.4), value: Int(distance))

                    Text("to destination")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Calculating distance…")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Destination name while active
            if let item = searchViewModel.selectedMapItem {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text(item.name ?? "Destination")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            // Stop button
            Button {
                tripMonitor.stop()
            } label: {
                Label("Stop Alert", systemImage: "stop.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.red, Color(red: 0.8, green: 0.1, blue: 0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Helpers

    private func formattedDistance(_ metres: Double) -> String {
        if metres >= 1000 {
            return String(format: "%.1f km", metres / 1000)
        } else {
            return "\(Int(metres)) m"
        }
    }
}
