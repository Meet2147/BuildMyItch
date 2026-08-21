import SwiftUI
import Charts

struct HistoryView: View {
    @Environment(ScanStore.self) private var store

    private var sortedScans: [FaceScan] {
        store.scans.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if store.scans.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            chartCard
                            deltaCard
                            scanList
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Progress")
            .toolbarBackground(Theme.background, for: .navigationBar)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(Theme.textSecondary)
            Text("No scans yet")
                .font(.headline)
            Text("Save your first scan and your score history will chart here. Re-scan weekly under similar lighting for the cleanest trend.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Jawline score over time")
                .font(.headline)
            Chart(store.scans.sorted { $0.date < $1.date }) { scan in
                LineMark(
                    x: .value("Date", scan.date),
                    y: .value("Score", scan.overallScore)
                )
                .foregroundStyle(Theme.accent)
                .interpolationMethod(.catmullRom)
                PointMark(
                    x: .value("Date", scan.date),
                    y: .value("Score", scan.overallScore)
                )
                .foregroundStyle(Theme.accent)
            }
            .chartYScale(domain: 0...100)
            .frame(height: 200)
        }
        .card()
    }

    @ViewBuilder
    private var deltaCard: some View {
        if sortedScans.count >= 2 {
            let latest = sortedScans[0].overallScore
            let first = sortedScans.last!.overallScore
            let delta = latest - first
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Since your first scan")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Text(String(format: "%+.1f points", delta))
                        .font(.title3.bold())
                        .foregroundStyle(delta >= 0 ? Theme.good : Theme.bad)
                }
                Spacer()
                Image(systemName: delta >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(delta >= 0 ? Theme.good : Theme.bad)
            }
            .card()
        }
    }

    private var scanList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("All scans")
                .font(.headline)
            ForEach(sortedScans) { scan in
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(scan.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline.bold())
                        Text("Angle \(Int(scan.metrics.gonialAngle))° · Width \(Int(scan.metrics.jawToFaceWidthRatio * 100))% · Sym \(Int(scan.metrics.symmetry * 100))%")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Text("\(Int(scan.overallScore.rounded()))")
                        .font(.title3.bold())
                        .foregroundStyle(Theme.scoreColor(scan.overallScore))
                }
                .card()
                .contextMenu {
                    Button(role: .destructive) {
                        store.delete(scan)
                    } label: {
                        Label("Delete scan", systemImage: "trash")
                    }
                }
            }
        }
    }
}

#Preview {
    HistoryView()
        .environment(ScanStore())
        .preferredColorScheme(.dark)
}
