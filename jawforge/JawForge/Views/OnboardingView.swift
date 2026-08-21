import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "faceid")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(Theme.accentGradient)

                VStack(spacing: 8) {
                    Text("JawForge")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                    Text("Scan. Measure. Sculpt.")
                        .font(.headline)
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 20) {
                    featureRow(icon: "camera.viewfinder",
                               title: "Scan your face",
                               text: "A single selfie is measured on-device — jaw angle, width, proportions and symmetry. Photos never leave your phone.")
                    featureRow(icon: "list.clipboard",
                               title: "Get your breakdown",
                               text: "Every metric scored and explained, so you know exactly what's already strong and what to work on.")
                    featureRow(icon: "flame",
                               title: "Train daily",
                               text: "A personalized routine — mewing, chin tucks, resistance work — with timers and a streak to keep you honest.")
                }
                .card()
                .padding(.horizontal)

                Text("JawForge is a fitness aid, not medical advice. Bone structure is genetic — exercises shape muscle, posture and habits. Stop any exercise that causes jaw pain.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button(action: onFinish) {
                    Text("Start scanning")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.black)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
    }

    private func featureRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Theme.accent)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.bold())
                Text(text)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    OnboardingView {}
        .preferredColorScheme(.dark)
}
