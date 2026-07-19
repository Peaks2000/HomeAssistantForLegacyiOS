import SwiftUI

@main
struct HomeAssistantLegacyWatchApp: App {
    @StateObject private var sessionStore = WatchSessionStore()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(sessionStore)
        }
    }
}
