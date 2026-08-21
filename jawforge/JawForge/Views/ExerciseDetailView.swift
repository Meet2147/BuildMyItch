import SwiftUI

struct ExerciseDetailView: View {
    @Environment(ScanStore.self) private var store
    let exercise: Exercise

    @State private var remaining: Int = 0
    @State private var timerRunning = false
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    timerCard
                    stepsCard
                    if let caution = exercise.caution {
                        cautionCard(caution)
                    }
                }
                .padding()
                .readableWidth()
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { remaining = exercise.durationSeconds }
        .onDisappear { stopTimer() }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: exercise.icon)
                .font(.largeTitle)
                .foregroundStyle(Theme.accentGradient)
                .frame(width: 64, height: 64)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.tagline)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Targets: \(exercise.targets)")
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
                Text(exercise.sets)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var timerCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().stroke(Theme.shadowDark.opacity(0.28), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.accentGradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: remaining)
                Text(timeString)
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
            }
            .frame(width: 160, height: 160)

            HStack(spacing: 12) {
                Button {
                    timerRunning ? stopTimer() : startTimer()
                } label: {
                    Label(timerRunning ? "Pause" : (remaining == exercise.durationSeconds ? "Start" : "Resume"),
                          systemImage: timerRunning ? "pause.fill" : "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                        .shadow(color: Theme.accent.opacity(0.4), radius: 8, y: 5)
                }
                Button {
                    stopTimer()
                    remaining = exercise.durationSeconds
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.headline)
                        .frame(width: 50, height: 50)
                        .foregroundStyle(Theme.ink)
                }
                .buttonStyle(NeuButtonStyle(cornerRadius: 14))
            }
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How to do it")
                .font(.headline)
            ForEach(Array(exercise.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .frame(width: 24, height: 24)
                        .background(Theme.accent.opacity(0.2), in: Circle())
                        .foregroundStyle(Theme.accent)
                    Text(step)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func cautionCard(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.warn)
            Text(text)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    // MARK: - Timer

    private var progress: Double {
        guard exercise.durationSeconds > 0 else { return 0 }
        return Double(exercise.durationSeconds - remaining) / Double(exercise.durationSeconds)
    }

    private var timeString: String {
        String(format: "%d:%02d", remaining / 60, remaining % 60)
    }

    private func startTimer() {
        timerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                guard remaining > 0 else { return }
                remaining -= 1
                if remaining == 0 {
                    stopTimer()
                    store.markCompleted(exercise.id)
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerRunning = false
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: ExerciseCatalog.all[2])
    }
    .environment(ScanStore())
}
