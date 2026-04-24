import SwiftUI

struct SetupView: View {
    @EnvironmentObject var bridgeManager: BridgeManager
    @EnvironmentObject var nightscoutManager: NightscoutManager
    @AppStorage("isSetupComplete") private var isSetupComplete = false

    @State private var carelinkUsername = ""
    @State private var carelinkPassword = ""
    @State private var nightscoutURL = ""
    @State private var apiSecret = ""
    @State private var isUS = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoggingIn = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("CareLink Credentials")) {
                    TextField("Username/Email", text: $carelinkUsername)
                        .textContentType(.username)
                        .autocapitalization(.none)

                    SecureField("Password", text: $carelinkPassword)
                        .textContentType(.password)

                    Toggle("US Server", isOn: $isUS)
                }

                Section(header: Text("Nightscout Configuration")) {
                    TextField("Nightscout URL", text: $nightscoutURL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)

                    SecureField("API Secret", text: $apiSecret)
                        .textContentType(.password)
                }

                Section {
                    Button(action: setupAndLogin) {
                        if isLoggingIn {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Setting up...")
                                    .padding(.leading, 8)
                                Spacer()
                            }
                        } else {
                            Text("Complete Setup")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isLoggingIn || !isFormValid)
                }
            }
            .navigationTitle("CGM Monitor Setup")
            .alert("Setup Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var isFormValid: Bool {
        !carelinkUsername.isEmpty &&
        !carelinkPassword.isEmpty &&
        !nightscoutURL.isEmpty &&
        !apiSecret.isEmpty
    }

    private func setupAndLogin() {
        isLoggingIn = true

        bridgeManager.configure(
            username: carelinkUsername,
            password: carelinkPassword,
            server: isUS ? "US" : "EU"
        )

        nightscoutManager.configure(
            url: nightscoutURL,
            apiSecret: apiSecret
        )

        Task {
            do {
                try await bridgeManager.login()

                await MainActor.run {
                    isSetupComplete = true
                    isLoggingIn = false

                    bridgeManager.startBridge()
                    nightscoutManager.startMonitoring()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoggingIn = false
                }
            }
        }
    }
}
