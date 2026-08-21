import SwiftUI

/// Five-screen onboarding quiz. Every answer feeds GuidanceEngine — nothing
/// is collected for its own sake.
struct OnboardingFlowView: View {
    let onFinish: (UserProfile) -> Void

    @State private var page = 0
    @State private var profile = UserProfile()
    private let pageCount = 5

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                progressHeader.readableWidth()
                TabView(selection: $page) {
                    welcomePage.tag(0)
                    aboutYouPage.tag(1)
                    lifestylePage.tag(2)
                    trainingPage.tag(3)
                    goalPage.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.snappy, value: page)

                footer
            }
        }
        .foregroundStyle(Theme.ink)
    }

    // MARK: - Chrome

    private var progressHeader: some View {
        HStack(spacing: 8) {
            if page > 0 {
                Button {
                    page -= 1
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.bold())
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(NeuButtonStyle(cornerRadius: 12))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.clear).neuInset(cornerRadius: 4)
                    Capsule()
                        .fill(Theme.accentGradient)
                        .frame(width: geo.size.width * Double(page + 1) / Double(pageCount))
                        .animation(.snappy, value: page)
                }
            }
            .frame(height: 8)
            Text("\(page + 1)/\(pageCount)")
                .font(.caption.bold())
                .foregroundStyle(Theme.textSecondary)
                .monospacedDigit()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .frame(height: 64)
    }

    private var footer: some View {
        NeuPrimaryButton(
            title: page == pageCount - 1 ? "Build my plan" : "Continue",
            icon: page == pageCount - 1 ? "wand.and.stars" : nil
        ) {
            if page < pageCount - 1 { page += 1 } else { onFinish(profile) }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 20)
        .readableWidth()
    }

    private func pageLayout<Content: View>(
        _ title: String, _ subtitle: String, @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.system(size: 27, weight: .heavy, design: .rounded))
                    Text(subtitle).font(.subheadline).foregroundStyle(Theme.textSecondary)
                }
                .padding(.top, 14)
                content()
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 20)
            .readableWidth()
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Pages

    private var welcomePage: some View {
        ScrollView {
            VStack(spacing: 22) {
                Image(systemName: "faceid")
                    .font(.system(size: 58, weight: .light))
                    .foregroundStyle(Theme.accentGradient)
                    .frame(width: 118, height: 118)
                    .neuRaised(cornerRadius: 36)
                    .padding(.top, 30)

                VStack(spacing: 6) {
                    Text("JawForge")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                    Text("Scan. Measure. Sculpt.")
                        .font(.headline)
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 18) {
                    welcomeRow(icon: "camera.viewfinder", title: "Scan your face",
                               text: "One selfie, measured on-device. Photos never leave your phone.")
                    welcomeRow(icon: "list.clipboard", title: "Know your numbers",
                               text: "Jaw angle, width, proportion and symmetry — scored and explained.")
                    welcomeRow(icon: "flame", title: "Train with a plan",
                               text: "A routine built from your scan and the answers you're about to give.")
                }
                .padding(18)
                .neuRaised()

                Text("A fitness aid, not medical advice. Bone structure is genetic — training shapes muscle, posture and habits.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.horizontal, 22)
        }
        .scrollIndicators(.hidden)
    }

    private func welcomeRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.bold())
                Text(text).font(.caption).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var aboutYouPage: some View {
        pageLayout("About you", "Age changes how fast muscle and posture respond — we tune expectations, not judgment.") {
            OptionGrid(title: "Your age", options: UserProfile.AgeRange.allCases,
                       selection: $profile.ageRange) { $0.rawValue }

            VStack(alignment: .leading, spacing: 12) {
                Text("Height & weight — optional")
                    .font(.subheadline.bold())
                Text("Jawline visibility tracks body-fat level more than any exercise. Sharing this helps us give honest guidance.")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
                HStack(spacing: 14) {
                    NeuStepper(label: "Height", unit: "cm", range: 130...220,
                               value: $profile.heightCm, defaultValue: 172)
                    NeuStepper(label: "Weight", unit: "kg", range: 35...180,
                               value: $profile.weightKg, defaultValue: 70)
                }
            }
            .padding(16)
            .neuRaised()
        }
    }

    private var lifestylePage: some View {
        pageLayout("Your lifestyle", "Daily habits quietly shape the lower face — these tell us where to look.") {
            OptionGrid(title: "How do you usually sleep?", options: UserProfile.SleepPosition.allCases,
                       selection: $profile.sleepPosition) { $0.rawValue }
            OptionGrid(title: "Which side do you chew on?", options: UserProfile.ChewingSide.allCases,
                       selection: $profile.chewingSide) { $0.rawValue }
            OptionGrid(title: "Do you breathe through your mouth?", options: UserProfile.MouthBreathing.allCases,
                       selection: $profile.mouthBreathing) { $0.rawValue }
            OptionGrid(title: "Screen time per day", options: UserProfile.ScreenHours.allCases,
                       selection: $profile.screenHours) { $0.rawValue }
        }
    }

    private var trainingPage: some View {
        pageLayout("Your training", "We match the routine to the time you'll actually give it — small and daily beats big and abandoned.") {
            OptionGrid(title: "How often do you work out?", options: UserProfile.WorkoutFrequency.allCases,
                       selection: $profile.workoutFrequency) { $0.rawValue }
            OptionGrid(title: "Time for jaw training each day", options: UserProfile.DailyMinutes.allCases,
                       selection: $profile.dailyMinutes) { $0.label }
        }
    }

    private var goalPage: some View {
        pageLayout("Your goal", "One primary focus — the routine leans toward it while still covering the fundamentals.") {
            OptionGrid(title: "What matters most to you?", options: UserProfile.Goal.allCases,
                       selection: $profile.goal) { $0.rawValue }

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Daily reminder").font(.subheadline.bold())
                    Text("A nudge at the time you usually train")
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Toggle("", isOn: $profile.remindersEnabled)
                    .labelsHidden()
                    .tint(Theme.accent)
            }
            .padding(16)
            .neuRaised()
        }
    }
}

/// Single-select neumorphic chip grid used by every quiz question.
struct OptionGrid<Option: Hashable>: View {
    let title: String
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline.bold())
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(options, id: \.self) { option in
                    let selected = option == selection
                    Button {
                        selection = option
                    } label: {
                        Text(label(option))
                            .font(.footnote.weight(selected ? .bold : .medium))
                            .foregroundStyle(selected ? Theme.accent : Theme.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .buttonStyle(.plain)
                    .modifier(selected ? AnyModifier(NeuInset(cornerRadius: 14)) : AnyModifier(NeuRaised(cornerRadius: 14)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selected ? Theme.accent.opacity(0.5) : .clear, lineWidth: 1.5)
                    )
                }
            }
        }
        .padding(16)
        .neuRaised()
    }
}

/// Optional numeric input rendered as a sunken well with +/- buttons.
struct NeuStepper: View {
    let label: String
    let unit: String
    let range: ClosedRange<Int>
    @Binding var value: Int?
    let defaultValue: Int

    var body: some View {
        VStack(spacing: 8) {
            Text(label).font(.caption.bold()).foregroundStyle(Theme.textSecondary)
            HStack(spacing: 10) {
                stepButton("minus") { adjust(-1) }
                Text(value.map { "\($0)" } ?? "—")
                    .font(.headline.monospacedDigit())
                    .frame(minWidth: 44)
                stepButton("plus") { adjust(1) }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .neuInset(cornerRadius: 14)
            Text(unit).font(.caption2).foregroundStyle(Theme.textSecondary)
        }
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(Theme.accent)
                .frame(width: 30, height: 30)
        }
        .buttonStyle(NeuButtonStyle(cornerRadius: 10))
    }

    private func adjust(_ delta: Int) {
        let next = (value ?? defaultValue) + delta
        value = min(range.upperBound, max(range.lowerBound, next))
    }
}

#Preview {
    OnboardingFlowView { _ in }
}
