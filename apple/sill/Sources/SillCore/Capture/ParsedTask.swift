//  ParsedTask.swift
//  What one line of typing becomes. Everything in here is a *suggestion*:
//  the capture field renders each field as an editable chip and nothing is
//  ever silently assigned.

import Foundation

public struct ParsedTask: Equatable, Sendable {
    public var title: String
    public var type: TaskType
    public var estimateMinutes: Int
    public var day: Date?
    public var band: Band?
    public var due: Date?
    public var recurrence: Recurrence?

    /// True when the user actually said how long it takes. When false the
    /// estimate came from `TaskType.defaultEstimate` and the chip renders in a
    /// lighter weight, because a guess shouldn't look like a decision.
    public var estimateWasStated: Bool
    /// True when the type came from keywords rather than a fallback rule.
    public var typeWasRecognised: Bool

    public init(
        title: String,
        type: TaskType = .admin,
        estimateMinutes: Int = 15,
        day: Date? = nil,
        band: Band? = nil,
        due: Date? = nil,
        recurrence: Recurrence? = nil,
        estimateWasStated: Bool = false,
        typeWasRecognised: Bool = false
    ) {
        self.title = title
        self.type = type
        self.estimateMinutes = estimateMinutes
        self.day = day
        self.band = band
        self.due = due
        self.recurrence = recurrence
        self.estimateWasStated = estimateWasStated
        self.typeWasRecognised = typeWasRecognised
    }
}
