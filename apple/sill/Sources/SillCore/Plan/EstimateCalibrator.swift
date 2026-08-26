//  EstimateCalibrator.swift
//
//  Sill learns exactly two things. Both are computed from data the app already
//  has, neither needs a model, and neither is ever shown to the user.
//
//  1. **When you actually do deep work.** From the timestamps of completed
//     deep tasks. After a couple of weeks it stops putting your hardest task
//     at 9am if you have never once finished one before eleven.
//
//  2. **How badly you over-commit.** Everyone plans more than they do. The
//     factor quietly shrinks tomorrow's plan to the size of a day you actually
//     finish — and it is never surfaced, because being told "you complete 60%
//     of what you plan" helps nobody.
//
//  Deliberately *not* learned: what matters, what you should be working on,
//  anything that needs a model of your goals. That isn't an app's business.

import Foundation

public struct DayOutcome: Equatable, Sendable {
    public var day: Date
    public var plannedMinutes: Int
    public var completedMinutes: Int

    public init(day: Date, plannedMinutes: Int, completedMinutes: Int) {
        self.day = day
        self.plannedMinutes = plannedMinutes
        self.completedMinutes = completedMinutes
    }
}

public struct DeepCompletion: Equatable, Sendable {
    public var completedAt: Date
    public init(completedAt: Date) { self.completedAt = completedAt }
}

public struct Calibration: Equatable, Sendable {
    /// Multiplier applied to every estimate when planning. Clamped to a sane
    /// range so one chaotic week can't halve the size of every future day.
    public var overcommitFactor: Double
    public var focusBand: Band
    public var sampleDays: Int
    public var deepSamples: Int

    /// Below this we're guessing, and the UI shouldn't imply otherwise.
    public var isConfident: Bool { sampleDays >= 10 }

    public static let unknown = Calibration(
        overcommitFactor: 1.0, focusBand: .morning, sampleDays: 0, deepSamples: 0
    )
}

public enum EstimateCalibrator {

    public static let minimumFactor = 1.0
    public static let maximumFactor = 2.5
    /// Below this many deep completions, "your focus band" is superstition.
    public static let minimumDeepSamples = 5

    public static func calibrate(
        outcomes: [DayOutcome],
        deepCompletions: [DeepCompletion],
        calendar: Calendar = .current
    ) -> Calibration {
        Calibration(
            overcommitFactor: factor(from: outcomes),
            focusBand: focusBand(from: deepCompletions, calendar: calendar),
            sampleDays: outcomes.filter { $0.completedMinutes > 0 }.count,
            deepSamples: deepCompletions.count
        )
    }

    // MARK: - Over-commitment

    static func factor(from outcomes: [DayOutcome]) -> Double {
        let ratios = outcomes
            .filter { $0.completedMinutes > 0 && $0.plannedMinutes > 0 }
            .map { Double($0.plannedMinutes) / Double($0.completedMinutes) }
        guard !ratios.isEmpty else { return minimumFactor }

        // Median, not mean: one day off sick shouldn't reshape the next month.
        let sorted = ratios.sorted()
        let median: Double
        if sorted.count.isMultiple(of: 2) {
            median = (sorted[sorted.count / 2 - 1] + sorted[sorted.count / 2]) / 2
        } else {
            median = sorted[sorted.count / 2]
        }

        // Ease in from 1.0 so the first few days don't swing the plan around.
        let confidence = min(1.0, Double(ratios.count) / 10.0)
        let eased = 1.0 + (median - 1.0) * confidence
        return min(maximumFactor, max(minimumFactor, eased))
    }

    // MARK: - Focus band

    static func focusBand(from completions: [DeepCompletion], calendar: Calendar) -> Band {
        guard completions.count >= minimumDeepSamples else { return .morning }

        var histogram: [Band: Int] = [:]
        for completion in completions {
            let band = Band.containing(completion.completedAt, calendar: calendar)
            guard band != .whenever else { continue }
            histogram[band, default: 0] += 1
        }
        guard let best = histogram.max(by: { lhs, rhs in
            lhs.value == rhs.value ? lhs.key > rhs.key : lhs.value < rhs.value
        }) else { return .morning }
        return best.key
    }
}
