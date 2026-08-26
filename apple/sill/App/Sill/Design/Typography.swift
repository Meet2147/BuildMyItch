//  Typography.swift
//  SF Pro, used properly. Three roles, and no screen invents a fourth.
//
//  The small-caps metadata style is the one that does the most work: it's what
//  makes a minimal UI read as typeset rather than unfinished.

import SwiftUI
import SillCore

public extension Font {
    /// Screen titles. Tight, because SF's default tracking is loose at size.
    static func sillTitle() -> Font { .system(.largeTitle, design: .default, weight: .semibold) }
    static func sillHeading() -> Font { .system(.title3, design: .default, weight: .semibold) }
    static func sillBody() -> Font { .system(.body) }
    /// Metadata: band headers, counts, durations.
    static func sillDetail() -> Font { .system(.caption, design: .default, weight: .medium) }
    /// Anything numeric that changes while you look at it.
    static func sillNumeric() -> Font { .system(.callout, design: .default, weight: .medium).monospacedDigit() }
}

public struct BandLabelStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    public func body(content: Content) -> some View {
        content
            .font(.sillDetail())
            .textCase(.uppercase)
            .tracking(1.6)
            .foregroundStyle(Stone.inkFaint(scheme))
    }
}

public extension View {
    func bandLabel() -> some View { modifier(BandLabelStyle()) }
}

public enum Durations {
    /// "2h", "45m", "1h 30m" — never "90 minutes", which is three times as wide
    /// and no clearer.
    public static func short(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        let rest = minutes % 60
        return rest == 0 ? "\(hours)h" : "\(hours)h \(rest)m"
    }

    /// For the empty state, where the tone is different: "3 hours back".
    public static func spoken(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) minutes" }
        let hours = Double(minutes) / 60
        let rounded = (hours * 2).rounded() / 2
        let text = rounded.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(rounded))
            : String(format: "%.1f", rounded)
        return rounded == 1 ? "an hour" : "\(text) hours"
    }
}
