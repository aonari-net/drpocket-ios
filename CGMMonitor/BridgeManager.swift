import Foundation

class BridgeManager: ObservableObject {
    @Published var isRunning = false
    @Published var lastSync: Date?
    @Published var loginStatus: String = "Not logged in"

    private var username: String = ""
    private var password: String = ""
    private var server: String = "EU"
    private var timer: Timer?

    func configure(username: String, password: String, server: String) {
        self.username = username
        self.password = password
        self.server = server
    }

    func login() async throws {
        guard !username.isEmpty, !password.isEmpty else {
            throw BridgeError.invalidCredentials
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["node", "--version"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus != 0 {
                throw BridgeError.nodeNotFound
            }

            await MainActor.run {
                self.loginStatus = "Logged in"
            }
        } catch {
            throw BridgeError.loginFailed(error.localizedDescription)
        }
    }

    func startBridge() {
        guard !isRunning else { return }

        isRunning = true

        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.syncData()
        }

        syncData()
    }

    func stopBridge() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private func syncData() {
        Task {
            do {
                try await performSync()
                await MainActor.run {
                    self.lastSync = Date()
                }
            } catch {
                print("Sync error: \(error)")
            }
        }
    }

    private func performSync() async throws {
        await Task.sleep(1_000_000_000)
    }
}

enum BridgeError: LocalizedError {
    case invalidCredentials
    case nodeNotFound
    case loginFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Username and password are required"
        case .nodeNotFound:
            return "Node.js not found. Please install Node.js to use this app."
        case .loginFailed(let message):
            return "Login failed: \(message)"
        }
    }
}
