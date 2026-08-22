import SwiftUI

struct ResultsView: View {
    @Environment(ScanStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let metrics: JawlineMetrics
    @State private var saved = false
    @State private var shareImage: UIImage?

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
                        potentialCard
                        faceShapeCard
                    }
                    .padding(.horizontal)

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
        .navigationTitle(Text("Your results"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let shareImage {
                    ShareLink(
                        item: Image(uiImage: shareImage),
                        preview: SharePreview(Text("My JawForge score"), image: Image(uiImage: shareImage))
                    ) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .onAppear { renderShareCard() }
    }

    @MainActor
    private func renderShareCard() {
        let renderer = ImageRenderer(content: ScoreShareCard(metrics: metrics))
        renderer.scale = 3
        shareImage = renderer.uiImage
    }

    private var potentialCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Your potential").font(.subheadline.bold())
                Text("Where consistent training can take you")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Text("\(Int(metrics.overallScore.rounded()))")
                .font(.title3.bold())
                .foregroundStyle(Theme.textSecondary)
            Image(systemName: "arrow.right")
                .font(.caption.bold())
                .foregroundStyle(Theme.accent)
            Text("\(Int(metrics.potentialScore.rounded()))")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(Theme.accent)
        }
        .card()
    }

    private var faceShapeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Face shape")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Text(metrics.faceShape.name)
                        .font(.headline)
                }
                Spacer()
                Image(systemName: "person.crop.square")
                    .font(.title2)
                    .foregroundStyle(Theme.accentGradient)
            }
            Text(metrics.faceShape.detail)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
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

/// The image people share — dark, branded, and readable in a feed.
struct ScoreShareCard: View {
    let metrics: JawlineMetrics

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 6) {
                Image(systemName: "faceid")
                Text(verbatim: "JawForge").font(.system(.headline, design: .rounded).weight(.black))
                Spacer()
                Text(metrics.faceShape.name)
                    .font(.caption.bold())
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(.white.opacity(0.12), in: Capsule())
            }
            .foregroundStyle(.white)

            VStack(spacing: 2) {
                Text("\(Int(metrics.overallScore.rounded()))")
                    .font(.system(size: 88, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(red: 0.18, green: 0.83, blue: 0.94), Color(red: 0.56, green: 0.42, blue: 1.0)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("Jawline score")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            VStack(spacing: 8) {
                ForEach(metrics.readings) { reading in
                    HStack {
                        Text(reading.name).font(.caption)
                        Spacer()
                        Text(reading.valueText).font(.caption.monospacedDigit())
                        Text(reading.band)
                            .font(.system(size: 9, weight: .heavy))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Theme.scoreColor(reading.score).opacity(0.25), in: Capsule())
                    }
                    .foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(14)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))

            Text("Scanned on-device with JawForge")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(26)
        .frame(width: 360)
        .background(
            LinearGradient(colors: [Color(red: 0.09, green: 0.11, blue: 0.16), Color(red: 0.05, green: 0.06, blue: 0.10)],
                           startPoint: .top, endPoint: .bottom)
        )
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
