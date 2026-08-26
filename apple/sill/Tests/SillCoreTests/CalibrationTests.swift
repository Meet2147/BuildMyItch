//  CalibrationTests.swift
//  Sill learns two things. It should learn them slowly, and stop well short of
//  anything that would need a model of what the user wants.

import Testing
import Foundation
@testable import SillCore

@Suite("Calibration")
struct CalibrationTests {

    private func outcome(planned: Int, completed: Int) -> DayOutcome {
        DayOutcome(day: Clock.day(2026, 8, 26), plannedMinutes: planned, completedMinutes: completed)
    }

    @Test("With no history we assume you estimate perfectly")
    func noHistory() {
        #expect(EstimateCalibrator.factor(from: []) == 1.0)
    }

    @Test("Ten consistent days move the factor all the way")
    func fullConfidence() {
        let outcomes = Array(repeating: outcome(planned: 200, completed: 100), count: 10)
        #expect(EstimateCalibrator.factor(from: outcomes) == 2.0)
    }

    @Test("Two days barely move it — the plan shouldn't swing on a bad Monday")
    func easesInSlowly() {
        let outcomes = Array(repeating: outcome(planned: 200, completed: 100), count: 2)
        let factor = EstimateCalibrator.factor(from: outcomes)
        #expect(abs(factor - 1.2) < 0.0001)
    }

    @Test("The factor is clamped, so one chaotic week can't halve every future day")
    func clamps() {
        let outcomes = Array(repeating: outcome(planned: 600, completed: 10), count: 20)
        #expect(EstimateCalibrator.factor(from: outcomes) == EstimateCalibrator.maximumFactor)

        // Finishing more than you planned doesn't mean we should plan you more.
        let overachiever = Array(repeating: outcome(planned: 60, completed: 300), count: 20)
        #expect(EstimateCalibrator.factor(from: overachiever) == EstimateCalibrator.minimumFactor)
    }

    @Test("A median, not a mean — one day off sick shouldn't reshape a month")
    func usesMedian() {
        var outcomes = Array(repeating: outcome(planned: 100, completed: 100), count: 9)
        outcomes.append(outcome(planned: 600, completed: 1))
        #expect(EstimateCalibrator.factor(from: outcomes) == 1.0)
    }

    @Test("Below five deep completions, 'your focus band' is superstition")
    func needsEvidence() {
        let evening = (0..<4).map { _ in DeepCompletion(completedAt: Clock.date(2026, 8, 26, 20, 0)) }
        #expect(EstimateCalibrator.focusBand(from: evening, calendar: Clock.calendar) == .morning)
    }

    @Test("With evidence, it stops putting your hardest task at 9am")
    func learnsTheBand() {
        let evening = (0..<6).map { _ in DeepCompletion(completedAt: Clock.date(2026, 8, 26, 20, 0)) }
        #expect(EstimateCalibrator.focusBand(from: evening, calendar: Clock.calendar) == .evening)
    }
}
