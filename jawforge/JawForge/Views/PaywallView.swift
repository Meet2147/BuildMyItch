import SwiftUI

/// JawForge Pro paywall. Shown once after onboarding, when the free scan
/// quota runs out, and from any "Unlock" affordance.
struct PaywallView: View {
    @Environment(Entitlements.self) private var entitlements
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: Entitlements.ProPlan = .annual

    private let features: [(String, String, String)] = [
        ("infinity", "Unlimited scans", "Free tier is 1 scan a week — Pro scans as often as you like and catches every change."),
        ("chart.line.uptrend.xyaxis", "Full progress history", "Every scan kept forever with trend deltas, not just your last 3."),
        ("wand.and.stars", "Adaptive routine", "Your plan re-personalizes after every scan and quiz answer."),
        ("list.clipboard", "Complete breakdowns", "All four metrics with explanations and a targeted game plan."),
        ("bell.badge", "Smart reminders", "Nudges tuned to the time you actually train."),
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 18) {
                        featureList
                        planPicker
                        Text("Cancel anytime in Settings. The annual plan starts with a 7-day free trial — you won't be charged until it ends.")
                            .font(.caption2)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 26)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    .readableWidth()
                }
                .scrollIndicators(.hidden)
                footer.readableWidth()
            }
        }
        .foregroundStyle(Theme.ink)
        .alert("Purchase issue", isPresented: .init(
            get: { entitlements.purchaseError != nil },
            set: { if !$0 { entitlements.purchaseError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(entitlements.purchaseError ?? "")
        }
        .onChange(of: entitlements.isPro) { _, pro in
            if pro { dismiss() }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(NeuButtonStyle(cornerRadius: 12))
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)

            Image(systemName: "crown.fill")
                .font(.system(size: 34))
                .foregroundStyle(Theme.accentGradient)
                .frame(width: 84, height: 84)
                .neuRaised(cornerRadius: 28)

            Text("JawForge Pro")
                .font(.system(size: 30, weight: .black, design: .rounded))
            Text("The full toolkit for a sharper jawline")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.bottom, 16)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 15) {
            ForEach(features, id: \.1) { icon, title, detail in
                HStack(alignment: .top, spacing: 13) {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 34, height: 34)
                        .neuInset(cornerRadius: 11)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.subheadline.bold())
                        Text(detail).font(.caption).foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(18)
        .neuRaised()
    }

    private var planPicker: some View {
        VStack(spacing: 12) {
            ForEach(Entitlements.ProPlan.allCases) { plan in
                let selected = plan == selectedPlan
                Button {
                    selectedPlan = plan
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 8) {
                                Text(plan.title).font(.subheadline.bold())
                                if let badge = plan.badge {
                                    Text(badge)
                                        .font(.system(size: 8.5, weight: .heavy))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 7).padding(.vertical, 3)
                                        .background(Theme.accentGradient, in: Capsule())
                                }
                            }
                            Text(plan.per).font(.caption).foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Text(entitlements.displayPrice(for: plan)).font(.headline.monospacedDigit())
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selected ? Theme.accent : Theme.textSecondary)
                    }
                    .padding(15)
                }
                .buttonStyle(.plain)
                .modifier(selected ? AnyModifier(NeuInset(cornerRadius: 16)) : AnyModifier(NeuRaised(cornerRadius: 16)))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(selected ? Theme.accent.opacity(0.5) : .clear, lineWidth: 1.5)
                )
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            ZStack {
                NeuPrimaryButton(
                    title: selectedPlan == .annual ? "Start 7-day free trial" : "Unlock JawForge Pro",
                    icon: "lock.open.fill"
                ) {
                    Task { await entitlements.purchase(selectedPlan) }
                }
                .opacity(entitlements.isPurchasing ? 0.35 : 1)
                if entitlements.isPurchasing {
                    ProgressView().tint(.white)
                }
            }
            .disabled(entitlements.isPurchasing)

            HStack(spacing: 18) {
                Button("Restore purchases") {
                    Task { await entitlements.restore() }
                }
                .disabled(entitlements.isPurchasing)
                Text("·").foregroundStyle(Theme.textSecondary)
                Link("Terms", destination: Entitlements.termsURL)
                Text("·").foregroundStyle(Theme.textSecondary)
                Link("Privacy", destination: Entitlements.privacyURL)
            }
            .font(.caption)
            .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

#Preview {
    PaywallView()
        .environment(Entitlements())
}
