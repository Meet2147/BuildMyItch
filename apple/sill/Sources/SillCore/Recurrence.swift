//  Recurrence.swift
//  Recurrence defaults to *after completion*, not fixed-interval.
//
//  "Water the plants every 5 days" means five days after you last did it.
//  Fixed-interval recurrence is the single biggest source of overdue-guilt in
//  every other todo app: miss one and it starts stacking copies of itself.
//  Fixed weekdays exist because "bins go out Tuesday" really is a Tuesday
//  thing — but you have to ask for it.

import Foundation

public struct Recurrence: Codable, Hashable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case afterCompletion
        case fixedWeekday
    }

    public var kind: Kind
    /// Days between completions, for `.afterCompletion`.
    public var days: Int
    /// `Calendar` weekday, 1 = Sunday ... 7 = Saturday, for `.fixedWeekday`.
    public var weekday: Int?

    public init(kind: Kind, days: Int = 1, weekday: Int? = nil) {
        self.kind = kind
        self.days = max(1, days)
        self.weekday = weekday
    }

    public static func every(_ days: Int) -> Recurrence {
        Recurrence(kind: .afterCompletion, days: days)
    }

    public static func everyWeekday(_ weekday: Int) -> Recurrence {
        Recurrence(kind: .fixedWeekday, days: 7, weekday: weekday)
    }

    /// The day the next occurrence should land on, given when this one was done.
    public func nextDay(after completion: Date, calendar: Calendar = .current) -> Date? {
        let from = calendar.startOfDay(for: completion)
        switch kind {
        case .afterCompletion:
            return calendar.date(byAdding: .day, value: days, to: from)
        case .fixedWeekday:
            guard let target = weekday else { return nil }
            let current = calendar.component(.weekday, from: from)
            var delta = target - current
            if delta <= 0 { delta += 7 }
            return calendar.date(byAdding: .day, value: delta, to: from)
        }
    }

    public var describedBriefly: String {
        switch kind {
        case .afterCompletion:
            return days == 1 ? "every day" : "every \(days) days"
        case .fixedWeekday:
            guard let weekday, (1...7).contains(weekday) else { return "weekly" }
            let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            return "every \(names[weekday - 1])"
        }
    }
}
