import SwiftUI

struct RootView: View {
    @Environment(ScanStore.self) private var store
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var showPostOnboardingPaywall = false

    var body: some View {
        TabView {
            ScanView()
                .tabItem { Label("Scan", systemImage: "faceid") }
            PlanView()
                .tabItem { Label("Train", systemImage: "figure.strengthtraining.traditional") }
            HistoryView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
        }
        .tint(Theme.accent)
        // Show the quiz until a profile exists — this also catches installs
        // upgraded from a build whose onboarding predated the quiz.
        .fullScreenCover(isPresented: .init(
            get: { !hasOnboarded || store.profile == nil },
            set: { _ in }   // dismissed only by completing the quiz
        )) {
            OnboardingFlowView { profile in
                store.setProfile(profile)
                hasOnboarded = true
                // Give the cover a beat to dismiss before the paywall slides up.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showPostOnboardingPaywall = true
                }
            }
        }
        .sheet(isPresented: $showPostOnboardingPaywall) {
            PaywallView()
        }
    }
}

#Preview {
    RootView()
        .environment(ScanStore())
        .environment(Entitlements())
}
