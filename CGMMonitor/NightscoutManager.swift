import Foundation

struct GlucoseReading: Identifiable {
    let id = UUID()
    let date: Date
    let mgdl: Int
    let trend: String?
}

struct CurrentGlucose {
    let value: String
    let trend: String?
    let timeAgo: String
}

class NightscoutManager: ObservableObject {
    @Published var glucoseReadings: [GlucoseReading] = []
    @Published var currentGlucose: CurrentGlucose?
    @Published var isConnected = false

    private var nightscoutURL: String = ""
    private var apiSecret: String = ""
    private var timer: Timer?

    func configure(url: String, apiSecret: String) {
        self.nightscoutURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        self.apiSecret = apiSecret
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.fetchData()
        }

        fetchData()
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func fetchData() {
        Task {
            await fetchGlucoseData()
        }
    }

    private func fetchGlucoseData() async {
        guard let url = URL(string: "\(nightscoutURL)/api/v1/entries.json?count=36") else {
            return
        }

        var request = URLRequest(url: url)
        request.setValue(apiSecret.sha1(), forHTTPHeaderField: "api-secret")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let entries = try JSONDecoder().decode([Entry].self, from: data)

            await MainActor.run {
                self.glucoseReadings = entries.map { entry in
                    GlucoseReading(
                        date: Date(timeIntervalSince1970: TimeInterval(entry.date) / 1000),
                        mgdl: entry.sgv,
                        trend: entry.direction
                    )
                }

                if let latest = entries.first {
                    let date = Date(timeIntervalSince1970: TimeInterval(latest.date) / 1000)
                    let timeAgo = self.timeAgoString(from: date)

                    self.currentGlucose = CurrentGlucose(
                        value: "\(latest.sgv)",
                        trend: latest.direction,
                        timeAgo: timeAgo
                    )
                }

                self.isConnected = true
            }
        } catch {
            print("Fetch error: \(error)")
            await MainActor.run {
                self.isConnected = false
            }
        }
    }

    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)

        if minutes < 1 {
            return "Just now"
        } else if minutes == 1 {
            return "1 min ago"
        } else {
            return "\(minutes) mins ago"
        }
    }
}

struct Entry: Codable {
    let sgv: Int
    let date: Int64
    let direction: String?
}

extension String {
    func sha1() -> String {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))

        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }

        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}

import CommonCrypto
