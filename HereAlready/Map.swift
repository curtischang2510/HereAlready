import SwiftUI
import MapKit

// MARK: - Main Map View

struct MapView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var tripMonitor: TripMonitor

    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198),
        latitudinalMeters: 1500,
        longitudinalMeters: 1500
    ))

    var body: some View {
        Map(position: $position) {
            // User's van marker
            if let location = locationManager.lastKnownLocation {
                Annotation("", coordinate: location.coordinate) {
                    VanMarkerView(heading: location.course)
                }
                .annotationTitles(.hidden)
            }

            // Destination pin (shown when trip is active or destination is selected)
            if let destination = tripMonitor.destination {
                Annotation("Destination", coordinate: destination) {
                    DestinationMarkerView()
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .all))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .ignoresSafeArea()
        .onReceive(locationManager.$lastKnownLocation) { newLocation in
            guard let location = newLocation else { return }
            withAnimation(.easeInOut(duration: 0.6)) {
                position = .camera(MapCamera(
                    centerCoordinate: location.coordinate,
                    distance: 600,
                    heading: 0,
                    pitch: 0
                ))
            }
        }
    }
}

// MARK: - Van Marker

struct VanMarkerView: View {
    /// CLLocation.course — degrees from north. Negative if unavailable.
    let heading: Double

    @State private var isPulsing = false

    private var rotationDegrees: Double {
        // Emoji 🚐 faces right (east = 90°). Subtract 90 so 0° heading → van faces north (up).
        (heading >= 0 ? heading : 0) - 90
    }

    var body: some View {
        ZStack {
            // Soft pulsing ring
            Circle()
                .fill(.blue.opacity(0.18))
                .frame(width: 62, height: 62)
                .scaleEffect(isPulsing ? 1.45 : 1.0)
                .animation(
                    .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                    value: isPulsing
                )

            // White card
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .frame(width: 44, height: 44)
                .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)

            // Van
            Text("🚐")
                .font(.system(size: 26))
                .rotationEffect(.degrees(rotationDegrees))
        }
        .onAppear { isPulsing = true }
    }
}

// MARK: - Destination Marker

struct DestinationMarkerView: View {
    @State private var isBouncing = false

    var body: some View {
        VStack(spacing: 0) {
            // Pin head
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.red, Color(red: 0.8, green: 0.1, blue: 0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .shadow(color: .red.opacity(0.45), radius: 8, x: 0, y: 4)

                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .offset(y: isBouncing ? -5 : 0)
            .animation(
                .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                value: isBouncing
            )

            // Pin tail
            PinTail()
                .fill(Color(red: 0.8, green: 0.1, blue: 0.1))
                .frame(width: 14, height: 10)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
        .onAppear { isBouncing = true }
    }
}

private struct PinTail: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
        }
    }
}
