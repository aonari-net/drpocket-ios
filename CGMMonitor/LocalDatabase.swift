import Foundation
import SQLite3

class LocalDatabase {
    private var db: OpaquePointer?
    private let dbPath: String

    init() {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        dbPath = documentsPath.appendingPathComponent("cgm_data.db").path

        openDatabase()
        createTables()
        cleanOldData()
    }

    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Error opening database")
        }
    }

    private func createTables() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS glucose_readings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER NOT NULL,
            mgdl INTEGER NOT NULL,
            trend TEXT,
            created_at INTEGER NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_timestamp ON glucose_readings(timestamp DESC);
        """

        if sqlite3_exec(db, createTableQuery, nil, nil, nil) != SQLITE_OK {
            print("Error creating table")
        }
    }

    func saveReading(timestamp: Date, mgdl: Int, trend: String?) {
        let insertQuery = "INSERT INTO glucose_readings (timestamp, mgdl, trend, created_at) VALUES (?, ?, ?, ?);"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, Int64(timestamp.timeIntervalSince1970))
            sqlite3_bind_int(statement, 2, Int32(mgdl))

            if let trend = trend {
                sqlite3_bind_text(statement, 3, (trend as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(statement, 3)
            }

            sqlite3_bind_int64(statement, 4, Int64(Date().timeIntervalSince1970))

            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error inserting reading")
            }
        }

        sqlite3_finalize(statement)
    }

    func getReadings(hours: Int = 3) -> [GlucoseReading] {
        var readings: [GlucoseReading] = []
        let cutoffTime = Date().addingTimeInterval(-Double(hours * 3600))

        let query = "SELECT timestamp, mgdl, trend FROM glucose_readings WHERE timestamp >= ? ORDER BY timestamp DESC;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, Int64(cutoffTime.timeIntervalSince1970))

            while sqlite3_step(statement) == SQLITE_ROW {
                let timestamp = sqlite3_column_int64(statement, 0)
                let mgdl = sqlite3_column_int(statement, 1)
                let trendPtr = sqlite3_column_text(statement, 2)
                let trend = trendPtr != nil ? String(cString: trendPtr!) : nil

                readings.append(GlucoseReading(
                    date: Date(timeIntervalSince1970: TimeInterval(timestamp)),
                    mgdl: Int(mgdl),
                    trend: trend
                ))
            }
        }

        sqlite3_finalize(statement)
        return readings
    }

    func getLatestReading() -> GlucoseReading? {
        let query = "SELECT timestamp, mgdl, trend FROM glucose_readings ORDER BY timestamp DESC LIMIT 1;"
        var statement: OpaquePointer?
        var reading: GlucoseReading?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                let timestamp = sqlite3_column_int64(statement, 0)
                let mgdl = sqlite3_column_int(statement, 1)
                let trendPtr = sqlite3_column_text(statement, 2)
                let trend = trendPtr != nil ? String(cString: trendPtr!) : nil

                reading = GlucoseReading(
                    date: Date(timeIntervalSince1970: TimeInterval(timestamp)),
                    mgdl: Int(mgdl),
                    trend: trend
                )
            }
        }

        sqlite3_finalize(statement)
        return reading
    }

    func cleanOldData() {
        let oneDayAgo = Date().addingTimeInterval(-86400)
        let deleteQuery = "DELETE FROM glucose_readings WHERE timestamp < ?;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, Int64(oneDayAgo.timeIntervalSince1970))

            if sqlite3_step(statement) == SQLITE_DONE {
                let deletedCount = sqlite3_changes(db)
                if deletedCount > 0 {
                    print("Cleaned \(deletedCount) old readings")
                }
            }
        }

        sqlite3_finalize(statement)
    }

    deinit {
        sqlite3_close(db)
    }
}
