import SwiftUI

@main
struct CGMMonitorApp: App {
    @StateObject private var bridgeManager = BridgeManager()
    @StateObject private var nightscoutManager = NightscoutManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bridgeManager)
                .environmentObject(nightscoutManager)
        }
    }
}
