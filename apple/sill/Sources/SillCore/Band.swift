//  Band.swift
//  A day has four bands, not 24 hours. Sill never puts a task at 10:15 —
//  time-boxing to the minute is a promise the day always breaks.

import Foundation

public enum Band: String, CaseIterable, Codable, Sendable {
    case morning, afternoon, evening
    /// No slot. Errands and anything that didn't fit live here.
    case whenever

    public var title: String {
        switch self {
        case .morning:   "This morning"
        case .afternoon: "After lunch"
        case .evening:   "This evening"
        case .whenever:  "Whenever"
        }
    }

    /// Hours the band covers, 24h clock. `whenever` covers nothing.
    public var hours: Range<Int>? {
        switch self {
        case .morning:   5..<12
        case .afternoon: 12..<17
        case .evening:   17..<23
        case .whenever:  nil
        }
    }

    /// Minutes the band nominally holds before any calendar is consulted.
    public var nominalCapacity: Int {
        switch self {
        case .morning:   180
        case .afternoon: 210
        case .evening:   120
        case .whenever:  .max
        }
    }

    public static func containing(hour: Int) -> Band {
        for band in [Band.morning, .afternoon, .evening] where band.hours?.contains(hour) == true {
            return band
        }
        return .whenever
    }

    public static func containing(_ date: Date, calendar: Calendar = .current) -> Band {
        containing(hour: calendar.component(.hour, from: date))
    }

    /// Bands in the order the day runs. `whenever` sorts last.
    public var order: Int {
        switch self {
        case .morning:   0
        case .afternoon: 1
        case .evening:   2
        case .whenever:  3
        }
    }
}

extension Band: Comparable {
    public static func < (a: Band, b: Band) -> Bool { a.order < b.order }
}
