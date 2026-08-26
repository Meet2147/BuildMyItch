//  DayPlan.swift
//  The output of planning. Deliberately a value type computed from tasks +
//  calendar rather than something stored: a derived plan can't conflict when
//  two devices produce it at the same time, so there's nothing to sync and
//  nothing to merge. Derive more, sync less.

import Foundation

public struct PlannableTask: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var type: TaskType
    public var estimateMinutes: Int
    public var due: Date?
    /// Set when the user dragged this into a band themselves. A pin always
    /// wins, even when it overflows the band — they know something we don't.
    public var pinned: Band?
    public var createdAt: Date

    public init(
        id: UUID,
        type: TaskType,
        estimateMinutes: Int,
        due: Date? = nil,
        pinned: Band? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.type = type
        self.estimateMinutes = estimateMinutes
        self.due = due
        self.pinned = pinned
        self.createdAt = createdAt
    }
}

public struct DayPlan: Equatable, Sendable {
    /// Task ids in the order they should be shown, per band.
    public var bands: [Band: [UUID]]
    /// Schedulable work that didn't fit today. Not shown on Today — a plan that
    /// lists what you failed to fit is just the guilt list again.
    public var overflow: [UUID]
    /// Idle work. Never scheduled, surfaced on the widget.
    public var idle: [UUID]
    /// Minutes committed per band, after the overcommit factor is applied.
    public var committedMinutes: [Band: Int]
    public var freeMinutes: [Band: Int]

    public init(
        bands: [Band: [UUID]] = [:],
        overflow: [UUID] = [],
        idle: [UUID] = [],
        committedMinutes: [Band: Int] = [:],
        freeMinutes: [Band: Int] = [:]
    ) {
        self.bands = bands
        self.overflow = overflow
        self.idle = idle
        self.committedMinutes = committedMinutes
        self.freeMinutes = freeMinutes
    }

    public func tasks(in band: Band) -> [UUID] { bands[band] ?? [] }

    public var scheduledCount: Int {
        Band.allCases.reduce(0) { $0 + (bands[$1]?.count ?? 0) }
    }

    /// What the empty state reports: "Nothing left. You've got 3 hours back."
    public var uncommittedMinutes: Int {
        Band.allCases
            .filter { $0 != .whenever }
            .reduce(0) { $0 + max(0, (freeMinutes[$1] ?? 0) - (committedMinutes[$1] ?? 0)) }
    }
}

public struct DayContext: Equatable, Sendable {
    public var day: Date
    /// Minutes genuinely free in each band, after the calendar is subtracted.
    public var freeMinutes: [Band: Int]
    /// The band this person actually does hard things in. Learned, not assumed.
    public var focusBand: Band
    /// Multiplier on every estimate. 1.0 means you estimate well; nobody does.
    public var overcommitFactor: Double

    public init(
        day: Date,
        freeMinutes: [Band: Int],
        focusBand: Band = .morning,
        overcommitFactor: Double = 1.0
    ) {
        self.day = day
        self.freeMinutes = freeMinutes
        self.focusBand = focusBand
        self.overcommitFactor = overcommitFactor
    }

    /// The fallback when we have no calendar access and no history yet.
    public static func nominal(day: Date) -> DayContext {
        var free: [Band: Int] = [:]
        for band in Band.allCases where band != .whenever {
            free[band] = band.nominalCapacity
        }
        return DayContext(day: day, freeMinutes: free)
    }
}
