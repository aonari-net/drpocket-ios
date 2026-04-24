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
    @Published var isConnected = true

    private let database: LocalDatabase
    private var timer: Timer?

    init(database: LocalDatabase) {
        self.database = database
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.fetchData()
        }

        fetchData()
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func fetchData() {
        glucoseReadings = database.getReadings(hours: 3)

        if let latest = database.getLatestReading() {
            let timeAgo = timeAgoString(from: latest.date)

            currentGlucose = CurrentGlucose(
                value: "\(latest.mgdl)",
                trend: latest.trend,
                timeAgo: timeAgo
            )
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
