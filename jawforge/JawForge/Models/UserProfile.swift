import Foundation

/// Everything the onboarding quiz collects. Each field feeds personalization:
/// routine composition, exercise emphasis, and copy in the guidance engine.
struct UserProfile: Codable, Equatable {
    enum AgeRange: String, Codable, CaseIterable {
        case teens = "13–17", twenties = "18–29", thirties = "30–39", forties = "40–49", fiftyPlus = "50+"
    }
    enum SleepPosition: String, Codable, CaseIterable {
        case back = "On my back", left = "Left side", right = "Right side", stomach = "Stomach", varies = "It varies"
    }
    enum ChewingSide: String, Codable, CaseIterable {
        case left = "Mostly left", right = "Mostly right", even = "Both evenly", unsure = "Never noticed"
    }
    enum MouthBreathing: String, Codable, CaseIterable {
        case often = "Often", sometimes = "Sometimes", rarely = "Rarely / never"
    }
    enum ScreenHours: String, Codable, CaseIterable {
        case low = "Under 4 h", medium = "4–8 h", high = "8+ h"
    }
    enum WorkoutFrequency: String, Codable, CaseIterable {
        case none = "Not currently", light = "1–2× a week", regular = "3–4× a week", intense = "5+× a week"
    }
    enum DailyMinutes: Int, Codable, CaseIterable {
        case five = 5, ten = 10, fifteen = 15
        var label: String { "\(rawValue) min / day" }
    }
    enum Goal: String, Codable, CaseIterable {
        case sharper = "Sharper jaw angle"
        case doubleChin = "Reduce double chin"
        case symmetry = "Fix asymmetry"
        case overall = "Overall definition"
    }

    var ageRange: AgeRange = .twenties
    var heightCm: Int?
    var weightKg: Int?
    var sleepPosition: SleepPosition = .varies
    var chewingSide: ChewingSide = .unsure
    var mouthBreathing: MouthBreathing = .sometimes
    var screenHours: ScreenHours = .medium
    var workoutFrequency: WorkoutFrequency = .light
    var dailyMinutes: DailyMinutes = .ten
    var goal: Goal = .overall
    var remindersEnabled = true

    /// Rough BMI, when the user shared height & weight — used only to decide
    /// how prominently to surface the body-fat guidance, never shown as a
    /// judgment.
    var bmi: Double? {
        guard let h = heightCm, let w = weightKg, h > 0 else { return nil }
        let meters = Double(h) / 100
        return Double(w) / (meters * meters)
    }
}
