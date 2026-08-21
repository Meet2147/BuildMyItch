import SwiftUI

/// Neumorphic ("soft UI") design system: one pale surface color everywhere,
/// with depth carved out by paired light/dark shadows instead of borders.
enum Theme {
    // The whole app sits on this one surface tone — that's the neumorphic rule.
    static let background = Color(red: 0.89, green: 0.91, blue: 0.95)   // #E3E8F2
    static let surface = background
    static let surfaceRaised = Color(red: 0.93, green: 0.95, blue: 0.98)
    static let shadowDark = Color(red: 0.64, green: 0.69, blue: 0.79)
    static let shadowLight = Color.white

    static let ink = Color(red: 0.16, green: 0.19, blue: 0.28)          // #293047
    static let textSecondary = Color(red: 0.45, green: 0.49, blue: 0.60)

    static let accent = Color(red: 0.09, green: 0.62, blue: 0.75)       // deep teal
    static let accentSecondary = Color(red: 0.45, green: 0.34, blue: 0.86) // violet
    static let good = Color(red: 0.13, green: 0.65, blue: 0.40)
    static let warn = Color(red: 0.83, green: 0.58, blue: 0.10)
    static let bad = Color(red: 0.83, green: 0.28, blue: 0.28)

    static let accentGradient = LinearGradient(
        colors: [accent, accentSecondary],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...: return good
        case 60..<80: return accent
        case 45..<60: return warn
        default: return bad
        }
    }
}

// MARK: - Neumorphic building blocks

/// Raised soft-UI panel: light from the top-left, shade to the bottom-right.
struct NeuRaised: ViewModifier {
    var cornerRadius: CGFloat = 20
    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: Theme.shadowDark.opacity(0.5), radius: 8, x: 6, y: 6)
                .shadow(color: Theme.shadowLight.opacity(0.9), radius: 8, x: -6, y: -6)
        )
    }
}

/// Sunken well — used for pressed states, inputs and progress tracks.
struct NeuInset: ViewModifier {
    var cornerRadius: CGFloat = 16
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return content.background(
            shape.fill(Theme.surface)
                .overlay(
                    shape.stroke(Theme.shadowDark.opacity(0.55), lineWidth: 3)
                        .blur(radius: 3)
                        .offset(x: 2, y: 2)
                        .mask(shape.fill(LinearGradient(colors: [.black, .clear],
                                                        startPoint: .topLeading, endPoint: .bottomTrailing)))
                )
                .overlay(
                    shape.stroke(Theme.shadowLight.opacity(0.9), lineWidth: 3)
                        .blur(radius: 3)
                        .offset(x: -2, y: -2)
                        .mask(shape.fill(LinearGradient(colors: [.clear, .black],
                                                        startPoint: .topLeading, endPoint: .bottomTrailing)))
                )
        )
    }
}

/// Soft push-button: raised at rest, sinks into the surface while pressed.
struct NeuButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 16
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(configuration.isPressed
                      ? AnyModifier(NeuInset(cornerRadius: cornerRadius))
                      : AnyModifier(NeuRaised(cornerRadius: cornerRadius)))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Type-erasing wrapper so NeuButtonStyle can swap modifiers conditionally.
struct AnyModifier: ViewModifier {
    private let apply: (AnyView) -> AnyView
    init<M: ViewModifier>(_ modifier: M) {
        apply = { AnyView($0.modifier(modifier)) }
    }
    func body(content: Content) -> some View { apply(AnyView(content)) }
}

/// Gradient call-to-action with a soft colored glow — the one loud element
/// allowed per screen in this design.
struct NeuPrimaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Theme.accent.opacity(0.45), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .modifier(NeuRaised(cornerRadius: 20))
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
    func neuRaised(cornerRadius: CGFloat = 20) -> some View { modifier(NeuRaised(cornerRadius: cornerRadius)) }
    func neuInset(cornerRadius: CGFloat = 16) -> some View { modifier(NeuInset(cornerRadius: cornerRadius)) }
}
