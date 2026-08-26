//  SoftStone.swift
//  The shipping implementation of the Soft Stone language.
//  Spec: apple/design-system/SOFT-STONE.md
//
//  The rule the whole file serves: relief encodes *structure*, never meaning.
//  Elevation tells you what is a surface, a container, a control. It never
//  tells you what is selected, urgent, done or disabled — those always carry
//  their own contrast. Flatten every shadow and the app still works.

import SwiftUI

// MARK: - Palette

public enum Stone {

    public static func ground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: 0x232220) : Color(hex: 0xECE9E4)
    }
    public static func raised(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: 0x2A2926) : Color(hex: 0xF0EDE8)
    }
    /// In dark mode the "light" is a lifted grey, not white. A white highlight
    /// on a dark ground reads as a glow rather than a bevel.
    public static func highlight(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: 0x38352F) : .white
    }
    public static func shade(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: 0x141311) : Color(hex: 0xC9C4BB)
    }

    public static func ink(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: 0xE7E3DA) : Color(hex: 0x3A3833)
    }
    public static func inkSoft(_ scheme: ColorScheme) -> Color { ink(scheme).opacity(0.60) }
    public static func inkFaint(_ scheme: ColorScheme) -> Color { ink(scheme).opacity(0.38) }

    /// Sill's one accent. Slate blue: it recedes, so it never competes with the
    /// task text it sits next to. Used in at most three places on a screen.
    public static func accent(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: 0x8E9CD8) : Color(hex: 0x5B6BA8)
    }
    /// The accent when it has to carry text — dark enough to clear 4.5:1.
    public static func accentInk(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: 0x9CA9E0) : Color(hex: 0x4A5A96)
    }

    public static func hairline(_ scheme: ColorScheme) -> Color { ink(scheme).opacity(0.16) }
}

// MARK: - Elevation

public enum Elevation: Int, CaseIterable, Sendable {
    case carved   = -1
    case flush    =  0
    case lifted   =  1
    case raised   =  2
    case floating =  3

    var offset: CGFloat {
        switch self {
        case .carved:   3
        case .flush:    0
        case .lifted:   3
        case .raised:   6
        case .floating: 12
        }
    }

    var blur: CGFloat {
        switch self {
        case .carved:   7
        case .flush:    0
        case .lifted:   9
        case .raised:   16
        case .floating: 28
        }
    }

    var isCarved: Bool { self == .carved }
}

// MARK: - Relief override
//
// The spec claims the app stays fully usable with every shadow at zero, and
// that there's a flag that proves it. This is that flag. Previews and the
// screenshot suite switch it on; if a state disappears when they do, it was
// encoded in relief, and that's a bug.
//
// It also stands in for Increase Contrast, which is read-only in the
// environment and so can't be forced in a preview.

public enum ReliefMode: String, Sendable {
    case normal
    case flattened
}

public struct SoftStoneReliefKey: EnvironmentKey {
    public static let defaultValue: ReliefMode = .normal
}

public extension EnvironmentValues {
    var softStoneRelief: ReliefMode {
        get { self[SoftStoneReliefKey.self] }
        set { self[SoftStoneReliefKey.self] = newValue }
    }
}

public extension View {
    /// Strip every shadow in this subtree. The app must remain fully legible.
    func softStoneFlattened(_ flattened: Bool = true) -> some View {
        environment(\.softStoneRelief, flattened ? .flattened : .normal)
    }
}

// MARK: - Surface

public struct SoftSurface: ViewModifier {
    let elevation: Elevation
    var radius: CGFloat

    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.softStoneRelief) private var relief

    /// Relief is dialled down on the Mac: shadows that read as soft on a 6"
    /// OLED read as muddy on a 27" display at arm's length.
    private var scale: CGFloat {
        #if os(macOS)
        0.7
        #else
        1.0
        #endif
    }

    /// Increase Contrast strips the relief and substitutes a hairline. The app
    /// has to stay fully legible with every shadow at zero, so we test in it.
    private var isFlattened: Bool { contrast == .increased || relief == .flattened }
    private var reliefOpacity: Double { isFlattened ? 0.28 : 1.0 }

    public func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        let offset = elevation.offset * scale
        let blur = elevation.blur * scale

        content
            .background {
                switch elevation {
                case .flush:
                    shape.fill(Stone.ground(scheme))
                case .carved:
                    shape
                        .fill(Stone.ground(scheme))
                        .overlay {
                            shape
                                .stroke(Stone.shade(scheme).opacity(reliefOpacity), lineWidth: offset)
                                .blur(radius: blur / 2)
                                .mask(shape)
                        }
                        .overlay {
                            shape
                                .stroke(Stone.highlight(scheme).opacity(reliefOpacity * 0.9), lineWidth: offset)
                                .blur(radius: blur / 2)
                                .offset(x: offset / 2, y: offset / 2)
                                .mask(shape)
                        }
                default:
                    shape
                        .fill(Stone.raised(scheme))
                        .shadow(color: Stone.shade(scheme).opacity(reliefOpacity),
                                radius: blur, x: offset, y: offset)
                        .shadow(color: Stone.highlight(scheme).opacity(reliefOpacity),
                                radius: blur, x: -offset, y: -offset)
                }
            }
            .overlay {
                if isFlattened {
                    shape.stroke(Stone.hairline(scheme), lineWidth: 1)
                }
            }
            // Relief is decoration. It must never be the only cue, and it is
            // never the thing VoiceOver reads.
            .accessibilityElement(children: .contain)
    }
}

public extension View {
    func softSurface(_ elevation: Elevation, radius: CGFloat = 18) -> some View {
        modifier(SoftSurface(elevation: elevation, radius: radius))
    }
}

// MARK: - Buttons

/// The press transition raised → carved is the point of the whole language,
/// and it is the only place a haptic fires — on the way down, never on release.
public struct SoftButtonStyle: ButtonStyle {
    var resting: Elevation = .raised
    var radius: CGFloat = 15

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(resting: Elevation = .raised, radius: CGFloat = 15) {
        self.resting = resting
        self.radius = radius
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .softSurface(configuration.isPressed ? .carved : resting, radius: radius)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .animation(reduceMotion ? nil : Motion.snap, value: configuration.isPressed)
            .sensoryFeedback(trigger: configuration.isPressed) { _, pressed in
                pressed ? .impact(weight: .light, intensity: 0.5) : nil
            }
    }
}

// MARK: - Colour helper

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
