import SwiftUI

@main
struct HereAlreadyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container.locationManager)
                .environmentObject(container.tripMonitor)
        }
    }
}
