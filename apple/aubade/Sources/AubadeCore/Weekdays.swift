//  Weekdays.swift
//  An empty set means a one-shot alarm — the "tomorrow only" case, which is
//  most alarms most people set.

import Foundation

public struct Weekdays: OptionSet, Codable, Hashable, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let sunday    = Weekdays(rawValue: 1 << 0)
    public static let monday    = Weekdays(rawValue: 1 << 1)
    public static let tuesday   = Weekdays(rawValue: 1 << 2)
    public static let wednesday = Weekdays(rawValue: 1 << 3)
    public static let thursday  = Weekdays(rawValue: 1 << 4)
    public static let friday    = Weekdays(rawValue: 1 << 5)
    public static let saturday  = Weekdays(rawValue: 1 << 6)

    public static let workweek: Weekdays = [.monday, .tuesday, .wednesday, .thursday, .friday]
    public static let weekend: Weekdays = [.saturday, .sunday]
    public static let everyDay: Weekdays = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]

    /// `Calendar` numbers weekdays 1 (Sunday) through 7 (Saturday).
    public static func from(calendarWeekday weekday: Int) -> Weekdays {
        Weekdays(rawValue: 1 << max(0, min(6, weekday - 1)))
    }

    public func contains(calendarWeekday weekday: Int) -> Bool {
        contains(Weekdays.from(calendarWeekday: weekday))
    }

    /// No days set means it rings once and then turns itself off.
    public var isOneShot: Bool { rawValue == 0 }

    /// "Mon–Fri", "Weekends", "Every day", or "Mon Wed Fri".
    public var shortLabel: String {
        if isOneShot { return "Once" }
        if self == .everyDay { return "Every day" }
        if self == .workweek { return "Mon–Fri" }
        if self == .weekend { return "Weekends" }
        let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return (0..<7)
            .filter { rawValue & (1 << $0) != 0 }
            .map { names[$0] }
            .joined(separator: " ")
    }
}
