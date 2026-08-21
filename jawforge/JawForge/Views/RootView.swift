import SwiftUI

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

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
        .fullScreenCover(isPresented: .init(
            get: { !hasOnboarded },
            set: { hasOnboarded = !$0 }
        )) {
            OnboardingView { hasOnboarded = true }
        }
    }
}

#Preview {
    RootView()
        .environment(ScanStore())
        .preferredColorScheme(.dark)
}
