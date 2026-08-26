//  DayPlannerTests.swift
//
//  The planner exists to enforce one promise: a day you can actually finish.
//  These tests are that promise, written down.

import Testing
import Foundation
@testable import SillCore

@Suite("Day planner")
struct DayPlannerTests {

    private func task(
        _ type: TaskType,
        _ minutes: Int,
        due: Date? = nil,
        pinned: Band? = nil,
        age: Int = 0
    ) -> PlannableTask {
        PlannableTask(
            id: UUID(),
            type: type,
            estimateMinutes: minutes,
            due: due,
            pinned: pinned,
            createdAt: Clock.calendar.date(byAdding: .day, value: -age, to: Clock.now)!
        )
    }

    private func context(
        morning: Int = 0, afternoon: Int = 0, evening: Int = 0,
        focus: Band = .morning, factor: Double = 1.0
    ) -> DayContext {
        DayContext(
            day: Clock.day(2026, 8, 26),
            freeMinutes: [.morning: morning, .afternoon: afternoon, .evening: evening],
            focusBand: focus,
            overcommitFactor: factor
        )
    }

    @Test("Forty-five free minutes gets forty-five minutes of work, not five items")
    func respectsCapacity() {
        let tasks = (0..<5).map { _ in task(.admin, 15) }
        let plan = DayPlanner.plan(tasks: tasks, context: context(afternoon: 45), calendar: Clock.calendar)

        #expect(plan.tasks(in: .afternoon).count == 3)
        #expect(plan.overflow.count == 2)
        #expect(plan.committedMinutes[.afternoon] == 45)
    }

    @Test("At most two deep tasks a day, however much room there is")
    func capsDeepWork() {
        let tasks = (0..<4).map { _ in task(.deep, 60) }
        let plan = DayPlanner.plan(tasks: tasks, context: context(morning: 600), calendar: Clock.calendar)

        #expect(plan.tasks(in: .morning).count == 2)
        #expect(plan.overflow.count == 2)
    }

    @Test("Deep work lands in the band you actually do deep work in")
    func usesLearnedFocusBand() {
        let plan = DayPlanner.plan(
            tasks: [task(.deep, 60)],
            context: context(morning: 600, evening: 600, focus: .evening),
            calendar: Clock.calendar
        )
        #expect(plan.tasks(in: .evening).count == 1)
        #expect(plan.tasks(in: .morning).isEmpty)
    }

    @Test("Idle work is never scheduled — that's what makes it idle")
    func idleIsNeverScheduled() {
        let plan = DayPlanner.plan(
            tasks: [task(.idle, 15), task(.idle, 15)],
            context: context(morning: 600, afternoon: 600),
            calendar: Clock.calendar
        )
        #expect(plan.idle.count == 2)
        #expect(plan.scheduledCount == 0)
        #expect(plan.overflow.isEmpty)
    }

    @Test("Errands go to whenever and never eat a band's budget")
    func errandsDoNotConsumeBudget() {
        let plan = DayPlanner.plan(
            tasks: [task(.errand, 30), task(.errand, 30), task(.admin, 15)],
            context: context(afternoon: 15),
            calendar: Clock.calendar
        )
        #expect(plan.tasks(in: .whenever).count == 2)
        #expect(plan.tasks(in: .afternoon).count == 1)
        #expect(plan.overflow.isEmpty)
    }

    @Test("A pin always wins, even when it overflows the band")
    func pinsAlwaysWin() {
        let plan = DayPlanner.plan(
            tasks: [task(.deep, 180, pinned: .morning)],
            context: context(morning: 30),
            calendar: Clock.calendar
        )
        #expect(plan.tasks(in: .morning).count == 1)
        #expect(plan.overflow.isEmpty)
    }

    @Test("Something genuinely due today is placed even on a full day")
    func deadlinesAreNeverDropped() {
        let due = Clock.date(2026, 8, 26, 17, 0)
        let plan = DayPlanner.plan(
            tasks: [task(.deep, 120, due: due)],
            context: context(),                       // no free time at all
            calendar: Clock.calendar
        )
        #expect(plan.overflow.isEmpty)
        #expect(plan.scheduledCount == 1)
    }

    @Test("Over-committing shrinks what fits, silently")
    func overcommitFactorShrinksTheDay() {
        let tasks = [task(.admin, 30), task(.admin, 30)]
        let honest = DayPlanner.plan(tasks: tasks, context: context(afternoon: 60), calendar: Clock.calendar)
        let realistic = DayPlanner.plan(tasks: tasks, context: context(afternoon: 60, factor: 1.5), calendar: Clock.calendar)

        #expect(honest.tasks(in: .afternoon).count == 2)
        #expect(realistic.tasks(in: .afternoon).count == 1)
    }

    @Test("Within a type, oldest first — nothing starves at the bottom")
    func oldestFirst() {
        let old = task(.admin, 15, age: 20)
        let new = task(.admin, 15, age: 0)
        let plan = DayPlanner.plan(tasks: [new, old], context: context(afternoon: 15), calendar: Clock.calendar)
        #expect(plan.tasks(in: .afternoon) == [old.id])
    }

    @Test("An empty day reports the time you got back")
    func reportsFreeTime() {
        let plan = DayPlanner.plan(tasks: [], context: context(morning: 120, afternoon: 60), calendar: Clock.calendar)
        #expect(plan.uncommittedMinutes == 180)
    }
}
