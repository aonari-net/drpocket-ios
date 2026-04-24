import SwiftUI

@main
struct CGMMonitorApp: App {
    private let database = LocalDatabase()
    @StateObject private var bridgeManager: BridgeManager
    @StateObject private var nightscoutManager: NightscoutManager

    init() {
        let db = LocalDatabase()
        _bridgeManager = StateObject(wrappedValue: BridgeManager(database: db))
        _nightscoutManager = StateObject(wrappedValue: NightscoutManager(database: db))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bridgeManager)
                .environmentObject(nightscoutManager)
        }
    }
}
