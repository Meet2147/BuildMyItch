import Foundation

/// A piece of advice generated from a scan, linked to the exercises that
/// address it.
struct Recommendation: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let exerciseIDs: [String]
}

/// Turns raw metrics into human guidance and a daily routine.
/// Pure functions — easy to unit test and tweak.
enum GuidanceEngine {
    static func recommendations(for m: JawlineMetrics) -> [Recommendation] {
        var recs: [Recommendation] = []

        if m.gonialAngleScore < 75 {
            recs.append(Recommendation(
                id: "angle",
                title: "Sharpen your jaw angle",
                detail: "Your jaw corner measures \(Int(m.gonialAngle))°, on the softer side. The masseter muscle sits right on that corner — training it adds visible width and hardness there. Chewing training and resistance presses are your highest-leverage work.",
                exerciseIDs: ["chewing", "jaw_resistance", "platysma_flex"]
            ))
        }
        if m.widthRatioScore < 75 {
            if m.jawToFaceWidthRatio < 0.80 {
                recs.append(Recommendation(
                    id: "width",
                    title: "Build jaw width",
                    detail: "Your jaw sits narrow relative to your upper face. Progressive chewing work grows the masseters, which sit exactly where width is measured — this is the most trainable metric of all.",
                    exerciseIDs: ["chewing", "jaw_resistance"]
                ))
            } else {
                recs.append(Recommendation(
                    id: "width",
                    title: "Refine rather than build",
                    detail: "Your jaw is already wide relative to your upper face, so skip heavy chewing work — focus on definition through posture and under-chin tightening instead.",
                    exerciseIDs: ["chin_tucks", "platysma_flex", "neck_curls"]
                ))
            }
        }
        if m.lowerFaceScore < 75 {
            recs.append(Recommendation(
                id: "proportion",
                title: "Rebalance the lower face",
                detail: "Your lower-face proportion sits outside the classical balance point. Consistent tongue posture (mewing) and chin tucks improve how the lower third carries — and posture changes photograph faster than you'd expect.",
                exerciseIDs: ["mewing", "chin_tucks", "vowel_stretch"]
            ))
        }
        if m.symmetryScore < 78 {
            recs.append(Recommendation(
                id: "symmetry",
                title: "Even out left/right balance",
                detail: "Your jaw sits slightly off your facial midline. The usual culprits are one-sided chewing, sleeping on one side, and leaning on one hand. Alternate chewing sides deliberately and add controlled side glides.",
                exerciseIDs: ["side_glide", "chewing", "vowel_stretch"]
            ))
        }

        recs.append(Recommendation(
            id: "foundation",
            title: "The two things that matter most",
            detail: "1) Body-fat percentage: no exercise outshines a lower body-fat level — the jawline you're building is revealed, not created, by leanness. 2) Posture: forward-head posture visually erases up to half your jawline. Chin tucks and all-day mewing are non-negotiable foundations.",
            exerciseIDs: ["mewing", "chin_tucks"]
        ))

        return recs
    }

    /// Picks today's routine: foundations first, then whatever targets the
    /// weakest metrics, tuned by the onboarding profile.
    ///
    /// Profile effects:
    /// - `dailyMinutes` sets routine size (5 min → 3 exercises, 10 → 4, 15 → 5).
    /// - Frequent mouth breathing promotes mewing emphasis (it already leads).
    /// - A one-sided chewing habit or side sleeping pulls in the side glide.
    /// - Heavy screen hours pull in chin tucks emphasis (already a foundation)
    ///   plus neck curls for the posture chain.
    /// - The stated goal breaks ranking ties in its favor.
    static func dailyRoutine(for metrics: JawlineMetrics?, profile: UserProfile? = nil) -> [Exercise] {
        var ids: [String] = ["mewing", "chin_tucks"]

        var ranked: [(String, Double)]
        if let m = metrics {
            ranked = [
                ("chewing", m.widthRatioScore),
                ("jaw_resistance", m.gonialAngleScore),
                ("side_glide", m.symmetryScore),
                ("vowel_stretch", m.lowerFaceScore),
                ("platysma_flex", (m.gonialAngleScore + m.lowerFaceScore) / 2),
                ("neck_curls", m.gonialAngleScore),
            ]
        } else {
            ranked = [
                ("chewing", 60), ("jaw_resistance", 62), ("side_glide", 70),
                ("vowel_stretch", 72), ("platysma_flex", 66), ("neck_curls", 68),
            ]
        }

        if let p = profile {
            func boost(_ id: String, _ amount: Double) {
                if let i = ranked.firstIndex(where: { $0.0 == id }) { ranked[i].1 -= amount }
            }
            if p.chewingSide == .left || p.chewingSide == .right { boost("side_glide", 15) }
            if p.sleepPosition == .left || p.sleepPosition == .right { boost("side_glide", 8) }
            if p.screenHours == .high { boost("neck_curls", 12) }
            switch p.goal {
            case .sharper: boost("jaw_resistance", 10); boost("chewing", 8)
            case .doubleChin: boost("platysma_flex", 12); boost("neck_curls", 10)
            case .symmetry: boost("side_glide", 14); boost("vowel_stretch", 8)
            case .overall: break
            }
        }

        let slots: Int = {
            switch profile?.dailyMinutes {
            case .five: return 1
            case .fifteen: return 3
            default: return 2
            }
        }()
        ranked.sort { $0.1 < $1.1 }
        ids.append(contentsOf: ranked.prefix(slots).map(\.0))
        return ids.compactMap(ExerciseCatalog.byID)
    }
}
