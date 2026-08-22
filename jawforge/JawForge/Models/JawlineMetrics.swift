import Foundation

/// Raw measurements extracted from one face scan.
///
/// All of these are frontal-photo proxies, not clinical cephalometric values:
/// - `gonialAngle` — angle (degrees) at the jaw corner between the ramus
///   direction (toward the ear) and the jaw body (toward the chin), averaged
///   over both sides. Lower reads as a sharper, more "hinged" jaw.
/// - `jawToFaceWidthRatio` — jaw-corner width divided by upper-face width.
/// - `lowerFaceRatio` — nose-base→chin height divided by eye-line→chin height.
/// - `symmetry` — 0…1, how evenly the jaw sits around the facial midline.
struct JawlineMetrics: Codable, Hashable {
    var gonialAngle: Double
    var jawToFaceWidthRatio: Double
    var lowerFaceRatio: Double
    var symmetry: Double
}

extension JawlineMetrics {
    var gonialAngleScore: Double {
        Self.bandScore(gonialAngle, ideal: 112...127, floor: 96...152)
    }
    var widthRatioScore: Double {
        Self.bandScore(jawToFaceWidthRatio, ideal: 0.80...0.94, floor: 0.62...1.08)
    }
    var lowerFaceScore: Double {
        Self.bandScore(lowerFaceRatio, ideal: 0.45...0.55, floor: 0.32...0.68)
    }
    var symmetryScore: Double {
        Self.bandScore(symmetry, ideal: 0.92...1.0, floor: 0.68...1.0)
    }

    /// Weighted blend; the jaw angle and symmetry dominate how "defined" a
    /// jawline reads, so they carry the most weight.
    var overallScore: Double {
        gonialAngleScore * 0.35
            + widthRatioScore * 0.25
            + symmetryScore * 0.25
            + lowerFaceScore * 0.15
    }

    /// Projected ceiling with consistent training: each metric gets a
    /// realistic trainable gain (masseter growth moves angle and width the
    /// most; habits move symmetry; posture nudges proportion), capped at 100
    /// and never below the current score.
    var potentialScore: Double {
        let projected = min(100, gonialAngleScore + 18) * 0.35
            + min(100, widthRatioScore + 14) * 0.25
            + min(100, symmetryScore + 8) * 0.25
            + min(100, lowerFaceScore + 6) * 0.15
        return max(projected, overallScore)
    }

    /// Coarse face-shape read from the same measurements.
    var faceShape: FaceShape {
        if lowerFaceRatio >= 0.56 { return .oblong }
        if jawToFaceWidthRatio >= 0.90 {
            return gonialAngle <= 128 ? .square : .round
        }
        if jawToFaceWidthRatio <= 0.78 {
            return lowerFaceRatio <= 0.48 ? .heart : .diamond
        }
        return .oval
    }

    /// 100 inside the ideal band, falling linearly to 25 at the floor band's
    /// edges, clamped to 25...100 beyond it.
    static func bandScore(_ value: Double, ideal: ClosedRange<Double>, floor: ClosedRange<Double>) -> Double {
        if ideal.contains(value) { return 100 }
        let distance: Double
        let span: Double
        if value < ideal.lowerBound {
            distance = ideal.lowerBound - value
            span = max(ideal.lowerBound - floor.lowerBound, .ulpOfOne)
        } else {
            distance = value - ideal.upperBound
            span = max(floor.upperBound - ideal.upperBound, .ulpOfOne)
        }
        let score = 100 - (distance / span) * 75
        return min(100, max(25, score))
    }

    static func band(for score: Double) -> String {
        switch score {
        case 85...: return String(localized: "Sharp")
        case 70..<85: return String(localized: "Defined")
        case 55..<70: return String(localized: "Developing")
        default: return String(localized: "Needs work")
        }
    }
}

enum FaceShape: String, Codable, CaseIterable {
    case square, oval, round, heart, diamond, oblong

    var name: String {
        switch self {
        case .square: return String(localized: "Square")
        case .oval: return String(localized: "Oval")
        case .round: return String(localized: "Round")
        case .heart: return String(localized: "Heart")
        case .diamond: return String(localized: "Diamond")
        case .oblong: return String(localized: "Oblong")
        }
    }

    var detail: String {
        switch self {
        case .square:
            return String(localized: "Wide, angular jaw close to your cheekbone width — the classic strong-jaw canvas. Definition work shows fast on this shape.")
        case .oval:
            return String(localized: "Balanced proportions with a gently tapered jaw — most styles suit this shape, and jaw training adds edge without hardening it.")
        case .round:
            return String(localized: "Soft angles with similar width and height — sharpening the jaw corner gives this shape the most visible payoff.")
        case .heart:
            return String(localized: "Wider upper face tapering to a narrow chin — masseter work balances the taper with a stronger jaw base.")
        case .diamond:
            return String(localized: "Prominent cheekbones with a narrower jaw and forehead — building jaw width frames the cheekbones even better.")
        case .oblong:
            return String(localized: "Longer than wide with an extended lower third — width-building work suits this shape more than length-adding habits.")
        }
    }
}

/// A single row of the results breakdown, ready for display.
struct MetricReading: Identifiable {
    let id: String
    let name: String
    let valueText: String
    let score: Double
    let explanation: String

    var band: String { JawlineMetrics.band(for: score) }
}

extension JawlineMetrics {
    var readings: [MetricReading] {
        [
            MetricReading(
                id: "angle",
                name: String(localized: "Jaw angle"),
                valueText: String(format: "%.0f°", gonialAngle),
                score: gonialAngleScore,
                explanation: String(localized: "The corner angle of your jaw. Around 112–127° reads as a sharp, chiseled hinge; larger angles read as a softer slope from ear to chin.")
            ),
            MetricReading(
                id: "width",
                name: String(localized: "Jaw width"),
                valueText: String(format: "%.0f%%", jawToFaceWidthRatio * 100),
                score: widthRatioScore,
                explanation: String(localized: "How wide your jaw corners sit relative to your upper face. 80–94% gives the classic tapered-but-strong look; well below that reads narrow, above it reads blocky.")
            ),
            MetricReading(
                id: "proportion",
                name: String(localized: "Lower-face balance"),
                valueText: String(format: "%.0f%%", lowerFaceRatio * 100),
                score: lowerFaceScore,
                explanation: String(localized: "Nose-to-chin height as a share of eyes-to-chin height. Close to 50% is the balanced classical proportion.")
            ),
            MetricReading(
                id: "symmetry",
                name: String(localized: "Symmetry"),
                valueText: String(format: "%.0f%%", symmetry * 100),
                score: symmetryScore,
                explanation: String(localized: "How evenly your jaw sits around your facial midline. One-sided chewing and sleeping habits show up here first.")
            ),
        ]
    }
}
