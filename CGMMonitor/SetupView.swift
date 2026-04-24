import SwiftUI

struct SetupView: View {
    @EnvironmentObject var bridgeManager: BridgeManager
    @EnvironmentObject var nightscoutManager: NightscoutManager
    @AppStorage("isSetupComplete") private var isSetupComplete = false

    @State private var carelinkUsername = ""
    @State private var carelinkPassword = ""
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

                Section {
                    Text("Data stored locally on device")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Automatically wiped after 24 hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
        !carelinkPassword.isEmpty
    }

    private func setupAndLogin() {
        isLoggingIn = true

        bridgeManager.configure(
            username: carelinkUsername,
            password: carelinkPassword,
            server: isUS ? "US" : "EU"
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
