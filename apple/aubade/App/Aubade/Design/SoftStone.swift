//  SoftStone.swift
//  Aubade's cut of the shared language. Same rules as Sill — one ground, light
//  fixed top-left, relief encodes structure and never meaning — with amber for
//  an accent and one addition Sill doesn't need: a night face.
//
//  (Yes, this duplicates Sill's copy. Extracting a shared SoftStoneKit package
//  is worth doing once both apps have stopped moving; doing it now would couple
//  two things that are still changing shape.)

import SwiftUI

// MARK: - Night

/// After bedtime the whole app drops to a near-black ground with amber-only
/// ink. Not a cosmetic dark mode: at 3am, ordinary dark mode is a torch, and
/// heavy relief at low brightness just reads as smudges.
public enum Nightness: String, Sendable {
    case day
    case night
}

public struct NightnessKey: EnvironmentKey {
    public static let defaultValue: Nightness = .day
}

public struct SoftStoneReliefKey: EnvironmentKey {
    public static let defaultValue: ReliefMode = .normal
}

public enum ReliefMode: String, Sendable {
    case normal
    case flattened
}

public extension EnvironmentValues {
    var nightness: Nightness {
        get { self[NightnessKey.self] }
        set { self[NightnessKey.self] = newValue }
    }
    var softStoneRelief: ReliefMode {
        get { self[SoftStoneReliefKey.self] }
        set { self[SoftStoneReliefKey.self] = newValue }
    }
}

public extension View {
    func nightFace(_ on: Bool = true) -> some View {
        environment(\.nightness, on ? .night : .day)
    }
    /// Strip every shadow. The app must stay completely usable — that's the
    /// acceptance test for the whole design language.
    func softStoneFlattened(_ flattened: Bool = true) -> some View {
        environment(\.softStoneRelief, flattened ? .flattened : .normal)
    }
}

// MARK: - Palette

public struct Palette: Sendable {
    public var ground: Color
    public var raised: Color
    public var highlight: Color
    public var shade: Color
    public var ink: Color
    public var accent: Color

    public var inkSoft: Color { ink.opacity(0.60) }
    public var inkFaint: Color { ink.opacity(0.38) }
    public var hairline: Color { ink.opacity(0.18) }

    public static func resolve(_ scheme: ColorScheme, _ nightness: Nightness) -> Palette {
        if nightness == .night {
            // Amber on near-black. Nothing else, at any brightness.
            return Palette(
                ground: Color(hex: 0x151311),
                raised: Color(hex: 0x1B1917),
                highlight: Color(hex: 0x241F1A),
                shade: Color(hex: 0x0B0A09),
                ink: Color(hex: 0xC08640),
                accent: Color(hex: 0xC08640)
            )
        }
        if scheme == .dark {
            return Palette(
                ground: Color(hex: 0x232220),
                raised: Color(hex: 0x2A2926),
                highlight: Color(hex: 0x38352F),
                shade: Color(hex: 0x141311),
                ink: Color(hex: 0xE7E3DA),
                accent: Color(hex: 0xDFA860)
            )
        }
        return Palette(
            ground: Color(hex: 0xECE9E4),
            raised: Color(hex: 0xF0EDE8),
            highlight: .white,
            shade: Color(hex: 0xC9C4BB),
            ink: Color(hex: 0x3A3833),
            accent: Color(hex: 0x8F5B1C)      // dark enough to carry text
        )
    }
}

/// Read the palette anywhere: `@Environment(\.self) private var env` is
/// clumsy, so this bundles the two lookups every view needs.
public struct PaletteReader<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.nightness) private var nightness
    let content: (Palette) -> Content

    public init(@ViewBuilder content: @escaping (Palette) -> Content) {
        self.content = content
    }

    public var body: some View {
        content(Palette.resolve(scheme, nightness))
    }
}

// MARK: - Elevation

public enum Elevation: Int, Sendable {
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
}

// MARK: - Surface

public struct SoftSurface: ViewModifier {
    let elevation: Elevation
    var radius: CGFloat

    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.nightness) private var nightness
    @Environment(\.softStoneRelief) private var relief

    private var isFlattened: Bool { contrast == .increased || relief == .flattened }

    /// Relief gets much subtler at night. At low brightness a heavy bevel
    /// stops reading as depth and starts reading as dirt on the screen.
    private var reliefOpacity: Double {
        if isFlattened { return 0.28 }
        return nightness == .night ? 0.45 : 1.0
    }

    public func body(content: Content) -> some View {
        let palette = Palette.resolve(scheme, nightness)
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        let offset = elevation.offset
        let blur = elevation.blur

        content
            .background {
                switch elevation {
                case .flush:
                    shape.fill(palette.ground)
                case .carved:
                    shape
                        .fill(palette.ground)
                        .overlay {
                            shape
                                .stroke(palette.shade.opacity(reliefOpacity), lineWidth: offset)
                                .blur(radius: blur / 2)
                                .mask(shape)
                        }
                        .overlay {
                            shape
                                .stroke(palette.highlight.opacity(reliefOpacity * 0.9), lineWidth: offset)
                                .blur(radius: blur / 2)
                                .offset(x: offset / 2, y: offset / 2)
                                .mask(shape)
                        }
                default:
                    shape
                        .fill(palette.raised)
                        .shadow(color: palette.shade.opacity(reliefOpacity), radius: blur, x: offset, y: offset)
                        .shadow(color: palette.highlight.opacity(reliefOpacity), radius: blur, x: -offset, y: -offset)
                }
            }
            .overlay {
                if isFlattened {
                    shape.stroke(palette.hairline, lineWidth: 1)
                }
            }
    }
}

public extension View {
    func softSurface(_ elevation: Elevation, radius: CGFloat = 18) -> some View {
        modifier(SoftSurface(elevation: elevation, radius: radius))
    }
}

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
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}
