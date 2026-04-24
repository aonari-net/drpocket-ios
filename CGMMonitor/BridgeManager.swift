import Foundation

class BridgeManager: ObservableObject {
    @Published var isRunning = false
    @Published var lastSync: Date?
    @Published var loginStatus: String = "Not logged in"

    private var username: String = ""
    private var password: String = ""
    private var server: String = "EU"
    private var timer: Timer?
    private let database: LocalDatabase

    init(database: LocalDatabase) {
        self.database = database
    }

    func configure(username: String, password: String, server: String) {
        self.username = username
        self.password = password
        self.server = server
    }

    func login() async throws {
        guard !username.isEmpty, !password.isEmpty else {
            throw BridgeError.invalidCredentials
        }

        try await authenticateCareLink()

        await MainActor.run {
            self.loginStatus = "Logged in"
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
        let readings = try await fetchCareLinkData()

        for reading in readings {
            database.saveReading(
                timestamp: reading.date,
                mgdl: reading.mgdl,
                trend: reading.trend
            )
        }

        database.cleanOldData()
    }

    private func authenticateCareLink() async throws {
        let baseURL = server == "US" ? "https://carelink.minimed.com" : "https://carelink.minimed.eu"

        guard let url = URL(string: "\(baseURL)/patient/sso/login") else {
            throw BridgeError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "username": username,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BridgeError.authenticationFailed
        }
    }

    private func fetchCareLinkData() async throws -> [GlucoseReading] {
        let baseURL = server == "US" ? "https://carelink.minimed.com" : "https://carelink.minimed.eu"

        guard let url = URL(string: "\(baseURL)/patient/connect/data") else {
            throw BridgeError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(CareLinkResponse.self, from: data)

        return response.sgs.map { sg in
            GlucoseReading(
                date: Date(timeIntervalSince1970: TimeInterval(sg.datetime) / 1000),
                mgdl: sg.sg,
                trend: sg.trend
            )
        }
    }
}

struct CareLinkResponse: Codable {
    let sgs: [SensorGlucose]
}

struct SensorGlucose: Codable {
    let sg: Int
    let datetime: Int64
    let trend: String?
}

enum BridgeError: LocalizedError {
    case invalidCredentials
    case invalidURL
    case authenticationFailed
    case loginFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Username and password are required"
        case .invalidURL:
            return "Invalid CareLink URL"
        case .authenticationFailed:
            return "CareLink authentication failed. Check credentials."
        case .loginFailed(let message):
            return "Login failed: \(message)"
        }
    }
}
