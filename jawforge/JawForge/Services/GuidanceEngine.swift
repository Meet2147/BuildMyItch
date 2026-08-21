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

    /// Picks today's 4-exercise routine: foundations first, then whatever
    /// targets the weakest metrics.
    static func dailyRoutine(for metrics: JawlineMetrics?) -> [Exercise] {
        var ids: [String] = ["mewing", "chin_tucks"]
        if let m = metrics {
            let ranked: [(String, Double)] = [
                ("chewing", m.widthRatioScore),
                ("jaw_resistance", m.gonialAngleScore),
                ("side_glide", m.symmetryScore),
                ("vowel_stretch", m.lowerFaceScore),
            ].sorted { $0.1 < $1.1 }
            ids.append(contentsOf: ranked.prefix(2).map(\.0))
        } else {
            ids.append(contentsOf: ["chewing", "jaw_resistance"])
        }
        return ids.compactMap(ExerciseCatalog.byID)
    }
}
