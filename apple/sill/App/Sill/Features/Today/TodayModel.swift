//  TodayModel.swift
//  Turns the stored tasks into the one screen the app is actually about.
//  The plan is recomputed here every time rather than stored — see
//  `architecture/SYNC.md` §3: a derived plan can't conflict between devices.

import Foundation
import SwiftUI
import SillCore

public struct TodaySection: Identifiable, Equatable {
    public var band: Band
    public var todos: [Todo]
    public var id: Band { band }
}

@Observable
public final class TodayModel {

    public var day: Date
    public var calibration: Calibration = .unknown
    /// Minutes free per band after the calendar is subtracted. Until Calendar
    /// access is wired up this is the nominal day.
    public var freeMinutes: [Band: Int] = [:]

    private let calendar: Calendar

    public init(day: Date = Date(), calendar: Calendar = .current) {
        self.calendar = calendar
        self.day = calendar.startOfDay(for: day)
        self.freeMinutes = DayContext.nominal(day: self.day).freeMinutes
    }

    public var context: DayContext {
        DayContext(
            day: day,
            freeMinutes: freeMinutes,
            focusBand: calibration.focusBand,
            overcommitFactor: calibration.overcommitFactor
        )
    }

    /// Everything the planner is allowed to consider for today: anything
    /// planned for today or earlier, anything due, and — the important one —
    /// anything with no date at all.
    ///
    /// That last case is the app's whole thesis. You dump things in without
    /// structure and Sill decides what today looks like; if undated work sat
    /// in the Pile until you scheduled it by hand, this would just be a list
    /// with extra steps. The planner is what stops that flooding the screen:
    /// it fills to capacity and the rest quietly overflows.
    ///
    /// A task planned for a *future* day is excluded — that's the one way to
    /// tell Sill "not yet".
    public func candidates(from all: [Todo]) -> [Todo] {
        all.filter { todo in
            guard todo.isOpen else { return false }
            if let planned = todo.plannedDay { return planned <= day }
            if let due = todo.due { return due < calendar.date(byAdding: .day, value: 1, to: day) ?? day }
            return true
        }
    }

    public func sections(from all: [Todo]) -> [TodaySection] {
        let open = candidates(from: all)
        let byID = Dictionary(uniqueKeysWithValues: open.map { ($0.id, $0) })
        let plan = DayPlanner.plan(tasks: open.map { $0.plannable() }, context: context, calendar: calendar)

        return Band.allCases.sorted().compactMap { band in
            let todos = plan.tasks(in: band).compactMap { byID[$0] }
            return todos.isEmpty ? nil : TodaySection(band: band, todos: todos)
        }
    }

    public func plan(from all: [Todo]) -> DayPlan {
        DayPlanner.plan(tasks: candidates(from: all).map { $0.plannable() }, context: context, calendar: calendar)
    }

    public func completedToday(from all: [Todo]) -> [Todo] {
        all.filter { todo in
            guard let done = todo.completedAt else { return false }
            return calendar.isDate(done, inSameDayAs: day)
        }
        .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    /// The header line. Written, not templated.
    public func subtitle(from all: [Todo]) -> String {
        let free = plan(from: all).uncommittedMinutes
        let weekday = day.formatted(.dateTime.weekday(.wide))
        guard free > 0 else { return weekday }
        return "\(weekday) · \(Durations.spoken(free)) free"
    }

    /// What the screen says when there's nothing left. A placeholder is a
    /// missed opportunity; this is a decision.
    public func emptyLine(from all: [Todo]) -> String {
        let done = completedToday(from: all).count
        let free = plan(from: all).uncommittedMinutes
        if done == 0 { return "Nothing planned. Add something, or don't." }
        if free >= 60 { return "Nothing left. You've got \(Durations.spoken(free)) back." }
        return "That's the day. Nothing left."
    }
}
