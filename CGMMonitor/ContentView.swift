import SwiftUI

struct ContentView: View {
    @EnvironmentObject var bridgeManager: BridgeManager
    @AppStorage("isSetupComplete") private var isSetupComplete = false

    var body: some View {
        if isSetupComplete {
            MonitorView()
        } else {
            SetupView()
        }
    }
}
