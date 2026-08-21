import SwiftUI
import Charts

struct HistoryView: View {
    @Environment(ScanStore.self) private var store
    @Environment(Entitlements.self) private var entitlements
    @State private var showPaywall = false

    private var sortedScans: [FaceScan] {
        store.scans.sorted { $0.date > $1.date }
    }

    /// Free tier keeps the latest few scans visible; the rest sit behind Pro.
    private var visibleScans: [FaceScan] {
        entitlements.isPro ? sortedScans : Array(sortedScans.prefix(Entitlements.freeHistoryLimit))
    }

    private var lockedCount: Int { sortedScans.count - visibleScans.count }

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
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
        .tint(Theme.accent)
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
            ForEach(visibleScans) { scan in
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
            if lockedCount > 0 {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(Theme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(lockedCount) older scan\(lockedCount == 1 ? "" : "s") locked")
                                .font(.subheadline.bold())
                            Text("JawForge Pro keeps your full history and trends")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Text("Unlock")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 13).padding(.vertical, 7)
                            .background(Theme.accentGradient, in: Capsule())
                    }
                    .card()
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    HistoryView()
        .environment(ScanStore())
        .environment(Entitlements())
}
