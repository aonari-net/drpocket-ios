import SwiftUI
import Charts

struct MonitorView: View {
    @EnvironmentObject var nightscoutManager: NightscoutManager
    @State private var showSettings = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                currentGlucoseView
                    .padding(.top, 60)

                Spacer()

                glucoseChartView
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private var currentGlucoseView: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(nightscoutManager.currentGlucose?.value ?? "--")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundColor(glucoseColor)

                if let trend = nightscoutManager.currentGlucose?.trend {
                    Text(trendArrow(for: trend))
                        .font(.system(size: 64))
                        .foregroundColor(glucoseColor)
                }
            }

            Text(nightscoutManager.currentGlucose?.timeAgo ?? "No data")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    private var glucoseChartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 3 Hours")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))

            if nightscoutManager.glucoseReadings.isEmpty {
                Text("Loading data...")
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                Chart {
                    ForEach(nightscoutManager.glucoseReadings) { reading in
                        LineMark(
                            x: .value("Time", reading.date),
                            y: .value("Glucose", reading.mgdl)
                        )
                        .foregroundStyle(Color.green)
                        .lineStyle(StrokeStyle(lineWidth: 3))

                        PointMark(
                            x: .value("Time", reading.date),
                            y: .value("Glucose", reading.mgdl)
                        )
                        .foregroundStyle(Color.green)
                    }

                    RuleMark(y: .value("High", 180))
                        .foregroundStyle(Color.yellow.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

                    RuleMark(y: .value("Low", 70))
                        .foregroundStyle(Color.red.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                }
                .chartYScale(domain: 40...400)
                .frame(height: 250)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    private var glucoseColor: Color {
        guard let glucose = nightscoutManager.currentGlucose,
              let value = Int(glucose.value) else {
            return .white
        }

        if value < 70 {
            return .red
        } else if value > 180 {
            return .yellow
        } else {
            return .green
        }
    }

    private func trendArrow(for trend: String) -> String {
        switch trend {
        case "DoubleUp": return "⇈"
        case "SingleUp": return "↑"
        case "FortyFiveUp": return "↗"
        case "Flat": return "→"
        case "FortyFiveDown": return "↘"
        case "SingleDown": return "↓"
        case "DoubleDown": return "⇊"
        default: return "→"
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("isSetupComplete") private var isSetupComplete = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Button("Reset Configuration", role: .destructive) {
                        isSetupComplete = false
                        dismiss()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
