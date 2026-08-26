//  Motion.swift
//  One spring, three tunings — the same three Sill uses, so the two apps move
//  like they were made by the same hand.

import SwiftUI

public enum Motion {
    public static let snap = Animation.spring(response: 0.28, dampingFraction: 0.86)
    public static let settle = Animation.spring(response: 0.44, dampingFraction: 0.82)
    /// Ambient. The sunrise gradient lives here — slow enough that you can't
    /// catch it moving.
    public static let drift = Animation.spring(response: 0.90, dampingFraction: 1.0)
}

public extension Font {
    /// The clock. Monospaced digits are non-negotiable: a time that jitters as
    /// the minute changes is the single most visible sign nobody cared.
    static func clock(_ size: CGFloat) -> Font {
        .system(size: size, weight: .light, design: .default).monospacedDigit()
    }
    static func aubadeTitle() -> Font { .system(.largeTitle, weight: .semibold) }
    static func aubadeBody() -> Font { .system(.body) }
    static func aubadeDetail() -> Font { .system(.caption, weight: .medium) }
}

public struct MetaLabel: ViewModifier {
    let palette: Palette
    public func body(content: Content) -> some View {
        content
            .font(.aubadeDetail())
            .textCase(.uppercase)
            .tracking(1.6)
            .foregroundStyle(palette.inkFaint)
    }
}

public extension View {
    func metaLabel(_ palette: Palette) -> some View { modifier(MetaLabel(palette: palette)) }
}
