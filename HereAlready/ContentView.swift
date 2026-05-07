import SwiftUI

struct ContentView: View {
    @StateObject var sharedSearchViewModel = SearchViewModel()

    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let bottomSafeArea = geometry.safeAreaInsets.bottom

            SlidingPanelView(
                sharedSearchViewModel: sharedSearchViewModel,
                screenHeight: screenHeight,
                bottomSafeArea: bottomSafeArea
            )
        }
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Sliding Panel

private struct SlidingPanelView: View {
    @ObservedObject var sharedSearchViewModel: SearchViewModel
    @EnvironmentObject var tripMonitor: TripMonitor
    @EnvironmentObject var locationManager: LocationManager

    let screenHeight: CGFloat
    let bottomSafeArea: CGFloat

    // Panel Y-offset positions
    var expandedOffset: CGFloat  { screenHeight * 0.05 }           // searching: nearly full screen
    var partialOffset: CGFloat   { screenHeight * 0.58 }           // destination selected: ~40% visible
    var collapsedOffset: CGFloat { screenHeight - 90 }             // default: just the search bar peeking

    var targetOffset: CGFloat {
        if sharedSearchViewModel.isFocused {
            return expandedOffset
        } else if sharedSearchViewModel.hasSelectedDestination || tripMonitor.isActive {
            return partialOffset
        } else {
            return collapsedOffset
        }
    }

    @State private var currentOffset: CGFloat = 0
    private let panelHeight: CGFloat

    init(sharedSearchViewModel: SearchViewModel, screenHeight: CGFloat, bottomSafeArea: CGFloat) {
        self.sharedSearchViewModel = sharedSearchViewModel
        self.screenHeight = screenHeight
        self.bottomSafeArea = bottomSafeArea
        self.panelHeight = screenHeight * 0.95 + bottomSafeArea
        _currentOffset = State(initialValue: screenHeight - 90)
    }

    var body: some View {
        ZStack(alignment: .top) {
            MapView()
                .edgesIgnoringSafeArea(.all)

            SearchPage(viewModel: sharedSearchViewModel)
                .frame(height: panelHeight)
                .offset(y: currentOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newOffset = currentOffset + value.translation.height
                            currentOffset = max(expandedOffset, min(collapsedOffset, newOffset))
                        }
                        .onEnded { value in
                            snapPanel(velocity: value.predictedEndTranslation.height)
                        }
                )
        }
        .overlay(alignment: .bottom) {
            LocationDeniedOverlay()
        }
        // Animate to target whenever state changes
        .onChange(of: sharedSearchViewModel.isFocused) { _, _ in animateToTarget() }
        .onChange(of: sharedSearchViewModel.hasSelectedDestination) { _, _ in animateToTarget() }
        .onChange(of: tripMonitor.isActive) { _, _ in animateToTarget() }
    }

    private func animateToTarget() {
        withAnimation(.interactiveSpring(response: 0.42, dampingFraction: 0.78, blendDuration: 0.2)) {
            currentOffset = targetOffset
        }
    }

    private func snapPanel(velocity: CGFloat) {
        let snapPoints = [expandedOffset, partialOffset, collapsedOffset]
        let nearest = snapPoints.min(by: { abs($0 - currentOffset) < abs($1 - currentOffset) }) ?? collapsedOffset
        withAnimation(.interactiveSpring(response: 0.42, dampingFraction: 0.78, blendDuration: 0.2)) {
            currentOffset = nearest
        }
    }
}

// MARK: - Permission Denied Overlay

private struct LocationDeniedOverlay: View {
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
            ZStack {
                Color.black.opacity(0.72).ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "location.slash.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.white)

                    Text("Location Access Required")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text("HereAlready needs your location to alert you before you miss your stop.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 36)

                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.large)
                }
                .padding()
            }
        }
    }
}
