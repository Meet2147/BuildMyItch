import SwiftUI

/// Central palette so every screen shares the same dark, athletic look.
enum Theme {
    static let background = Color(red: 0.05, green: 0.06, blue: 0.09)
    static let surface = Color(red: 0.10, green: 0.12, blue: 0.16)
    static let surfaceRaised = Color(red: 0.14, green: 0.16, blue: 0.21)
    static let accent = Color(red: 0.23, green: 0.79, blue: 0.90)
    static let accentSecondary = Color(red: 0.55, green: 0.42, blue: 0.98)
    static let good = Color(red: 0.30, green: 0.85, blue: 0.55)
    static let warn = Color(red: 0.98, green: 0.75, blue: 0.30)
    static let bad = Color(red: 0.96, green: 0.42, blue: 0.42)
    static let textSecondary = Color.white.opacity(0.62)

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

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}
