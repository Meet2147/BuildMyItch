//  SoftStone.swift
//  Token layer + surface modifier for the Soft Stone design language.
//  Sketch quality: enough to prove the elevation ladder is a real system and
//  not a pile of ad-hoc shadows. Shared by Cairn and Aubade.

import SwiftUI

// MARK: - Palette

public enum Stone {
    /// Light source is fixed top-left on every element, in every locale.
    /// Never mirrored for RTL — light doesn't flip when the language does.
    public static let lightAngle = (dx: -1.0, dy: -1.0)

    public static func ground(_ s: ColorScheme) -> Color {
        s == .dark ? Color(hex: 0x22242B) : Color(hex: 0xE9EBF0)
    }
    public static func raised(_ s: ColorScheme) -> Color {
        s == .dark ? Color(hex: 0x282B33) : Color(hex: 0xEDEFF4)
    }
    /// In dark mode the highlight is a lifted grey, not white — a white
    /// highlight on a dark ground reads as a glow, not a bevel.
    public static func highlight(_ s: ColorScheme) -> Color {
        s == .dark ? Color(hex: 0x34373F) : .white
    }
    public static func shade(_ s: ColorScheme) -> Color {
        s == .dark ? Color(hex: 0x15171C) : Color(hex: 0xC3C7D2)
    }

    public static func ink(_ s: ColorScheme) -> Color {
        s == .dark ? Color(hex: 0xE4E6EC) : Color(hex: 0x3A3D46)
    }
    public static func inkSoft(_ s: ColorScheme) -> Color { ink(s).opacity(0.58) }
}

// MARK: - Elevation ladder

public enum Elevation: Int, CaseIterable {
    case carved   = -1   // text fields, tracks — the well a control sits in
    case flush    =  0   // the ground itself
    case lifted   =  1   // rows, chips, secondary buttons
    case raised   =  2   // cards, primary button, clock face
    case floating =  3   // sheets, popovers, the ringing alarm

    var offset: CGFloat {
        switch self {
        case .carved: 3; case .flush: 0; case .lifted: 3; case .raised: 6; case .floating: 12
        }
    }
    var blur: CGFloat {
        switch self {
        case .carved: 6; case .flush: 0; case .lifted: 9; case .raised: 16; case .floating: 28
        }
    }
    var isInset: Bool { self == .carved }
}

// MARK: - Motion

public enum Motion {
    public static let snap   = Animation.spring(response: 0.28, dampingFraction: 0.86)
    public static let settle = Animation.spring(response: 0.44, dampingFraction: 0.82)
    public static let drift  = Animation.spring(response: 0.90, dampingFraction: 1.00)
}

// MARK: - Surface

public struct SoftSurface: ViewModifier {
    let elevation: Elevation
    var radius: CGFloat = 18

    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    #if os(macOS)
    // Relief is dialed down on Mac: shadows that read as soft on a 6" OLED
    // read as muddy on a 27" display at arm's length.
    private let scale: CGFloat = 0.7
    #else
    private let scale: CGFloat = 1.0
    #endif

    /// Increase Contrast strips the relief and substitutes a hairline —
    /// the app must stay fully legible with every shadow at zero.
    private var reliefOpacity: Double { contrast == .increased ? 0.30 : 1.0 }

    public func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        let o = elevation.offset * scale
        let b = elevation.blur * scale

        content
            .background {
                if elevation.isInset {
                    shape.fill(Stone.ground(scheme))
                        .overlay { shape.stroke(Stone.shade(scheme), lineWidth: 2).blur(radius: b).mask(shape) }
                } else if elevation == .flush {
                    shape.fill(Stone.ground(scheme))
                } else {
                    shape.fill(Stone.raised(scheme))
                        .shadow(color: Stone.shade(scheme).opacity(reliefOpacity), radius: b, x: o, y: o)
                        .shadow(color: Stone.highlight(scheme).opacity(reliefOpacity), radius: b, x: -o, y: -o)
                }
            }
            .overlay {
                if contrast == .increased {
                    shape.stroke(Stone.ink(scheme).opacity(0.20), lineWidth: 1)
                }
            }
            // Relief is decoration; it must never be the only cue, so it is
            // hidden from assistive technology entirely.
            .accessibilityHidden(false)
    }
}

public extension View {
    func softSurface(_ e: Elevation, radius: CGFloat = 18) -> some View {
        modifier(SoftSurface(elevation: e, radius: radius))
    }
}

// MARK: - Button

/// The press transition raised → carved is the whole point of the language.
/// Haptic fires on press-down only, never on release.
public struct SoftButtonStyle: ButtonStyle {
    var resting: Elevation = .raised
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20).padding(.vertical, 12)
            .softSurface(configuration.isPressed ? .carved : resting, radius: 14)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .animation(reduceMotion ? nil : Motion.snap, value: configuration.isPressed)
            #if os(iOS)
            .sensoryFeedback(.impact(weight: .light, intensity: 0.5),
                             trigger: configuration.isPressed) { _, pressed in pressed }
            #endif
    }
}

// MARK: - Debug

/// Flip this in the screenshot suite: the app must be fully usable with the
/// entire visual language switched off. If a state disappears, it was encoded
/// in relief and that's a bug.
public enum SoftStoneDebug {
    @MainActor public static var flattenRelief = false
}

private extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red:   Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >>  8) & 0xFF) / 255,
                  blue:  Double( hex        & 0xFF) / 255)
    }
}
