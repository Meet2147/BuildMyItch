import SwiftUI

struct ResultsView: View {
    @Environment(ScanStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let metrics: JawlineMetrics
    @State private var saved = false

    private var recommendations: [Recommendation] {
        GuidanceEngine.recommendations(for: metrics)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    scoreRing
                        .padding(.top, 12)

                    VStack(spacing: 12) {
                        ForEach(metrics.readings) { reading in
                            MetricRow(reading: reading)
                        }
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Your game plan")
                            .font(.title3.bold())
                        ForEach(recommendations) { rec in
                            RecommendationCard(recommendation: rec)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    Text("Measurements are frontal-photo estimates and vary with lighting, angle and expression — scan under similar conditions each time and watch the trend, not a single number. Not medical advice.")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 90)
                }
                .readableWidth()
            }

            VStack {
                Spacer()
                saveButton.readableWidth()
            }
        }
        .navigationTitle("Your results")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var scoreRing: some View {
        let score = metrics.overallScore
        return VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Theme.surface)
                    .shadow(color: Theme.shadowDark.opacity(0.5), radius: 10, x: 7, y: 7)
                    .shadow(color: Theme.shadowLight.opacity(0.9), radius: 10, x: -7, y: -7)
                Circle()
                    .stroke(Theme.shadowDark.opacity(0.28), lineWidth: 14)
                    .padding(10)
                Circle()
                    .trim(from: 0, to: score / 100)
                    .stroke(Theme.accentGradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(10)
                VStack(spacing: 2) {
                    Text("\(Int(score.rounded()))")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                    Text(JawlineMetrics.band(for: score))
                        .font(.subheadline.bold())
                        .foregroundStyle(Theme.scoreColor(score))
                }
            }
            .frame(width: 180, height: 180)

            Text("Jawline score")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var saveButton: some View {
        Button {
            guard !saved else { return }
            store.add(FaceScan(metrics: metrics))
            saved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
        } label: {
            Label(saved ? "Saved" : "Save scan to progress",
                  systemImage: saved ? "checkmark.circle.fill" : "square.and.arrow.down")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    saved ? AnyShapeStyle(Theme.good) : AnyShapeStyle(Theme.accentGradient),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .foregroundStyle(.white)
                .shadow(color: (saved ? Theme.good : Theme.accent).opacity(0.45), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

struct MetricRow: View {
    let reading: MetricReading
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(reading.name).font(.subheadline.bold())
                    Text(reading.valueText)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text(reading.band)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.scoreColor(reading.score).opacity(0.18), in: Capsule())
                    .foregroundStyle(Theme.scoreColor(reading.score))
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.shadowDark.opacity(0.3))
                    Capsule()
                        .fill(Theme.scoreColor(reading.score))
                        .frame(width: geo.size.width * reading.score / 100)
                }
            }
            .frame(height: 6)

            if expanded {
                Text(reading.explanation)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .card()
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.snappy) { expanded.toggle() }
        }
    }
}

struct RecommendationCard: View {
    let recommendation: Recommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(recommendation.title)
                .font(.subheadline.bold())
            Text(recommendation.detail)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(recommendation.exerciseIDs, id: \.self) { id in
                        if let exercise = ExerciseCatalog.byID(id) {
                            NavigationLink {
                                ExerciseDetailView(exercise: exercise)
                            } label: {
                                Label(exercise.name, systemImage: exercise.icon)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(Theme.surfaceRaised, in: Capsule())
                                    .overlay(Capsule().stroke(Theme.shadowDark.opacity(0.35), lineWidth: 1))
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                    }
                }
            }
        }
        .card()
    }
}

#Preview {
    NavigationStack {
        ResultsView(metrics: JawlineMetrics(
            gonialAngle: 134,
            jawToFaceWidthRatio: 0.77,
            lowerFaceRatio: 0.51,
            symmetry: 0.9
        ))
    }
    .environment(ScanStore())
}
