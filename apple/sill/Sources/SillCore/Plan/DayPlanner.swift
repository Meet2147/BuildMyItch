//  DayPlanner.swift
//
//  Takes the deciding job off the user.
//
//  The rule the whole thing serves: if today has ninety free minutes, today
//  gets ninety minutes of tasks. Three items, not eleven. A plan you can't
//  finish isn't a plan, it's a list of ways to feel behind.

import Foundation

public enum DayPlanner {

    public static func plan(tasks: [PlannableTask], context: DayContext, calendar: Calendar = .current) -> DayPlan {
        var plan = DayPlan(freeMinutes: context.freeMinutes)
        var remaining: [Band: Int] = context.freeMinutes
        var bands: [Band: [UUID]] = [:]
        var committed: [Band: Int] = [:]

        let (idle, schedulable) = split(tasks)
        plan.idle = idle.map(\.id)

        func cost(_ task: PlannableTask) -> Int {
            Int((Double(task.estimateMinutes) * context.overcommitFactor).rounded(.up))
        }

        func place(_ task: PlannableTask, in band: Band) {
            bands[band, default: []].append(task.id)
            committed[band, default: 0] += cost(task)
            if band != .whenever {
                remaining[band] = (remaining[band] ?? 0) - cost(task)
            }
        }

        // 1. Pins first, and they always fit — the user put them there.
        for task in schedulable {
            guard let pinned = task.pinned else { continue }
            place(task, in: pinned)
        }

        // 2. Anything actually due today gets placed before anything else,
        //    even if the day is already full. A missed hard deadline is the one
        //    failure the app is responsible for.
        let free = schedulable.filter { $0.pinned == nil }
        let (dueToday, rest) = free.partitioned { isDue($0, on: context.day, calendar: calendar) }

        for task in dueToday.sorted(by: byDueThenAge) {
            let preferred = preferredBand(for: task, context: context)
            place(task, in: earliestBandWithRoom(cost(task), remaining, preferred: preferred))
        }

        // 3. Everything else, by type, into the band that suits its shape.
        var deepPlaced = 0
        for task in rest.sorted(by: byTypeThenAge) {
            let band = preferredBand(for: task, context: context)

            if task.type == .deep {
                if let cap = TaskType.deep.dailyCap, deepPlaced >= cap {
                    plan.overflow.append(task.id)
                    continue
                }
            }
            // Errands never consume a budget — they're not time you sit down for.
            if band == .whenever {
                place(task, in: .whenever)
                continue
            }
            guard (remaining[band] ?? 0) >= cost(task) else {
                plan.overflow.append(task.id)
                continue
            }
            place(task, in: band)
            if task.type == .deep { deepPlaced += 1 }
        }

        plan.bands = bands
        plan.committedMinutes = committed
        return plan
    }

    // MARK: - Placement rules

    private static func preferredBand(for task: PlannableTask, context: DayContext) -> Band {
        switch task.type {
        case .deep:   context.focusBand
        case .admin:  .afternoon
        case .social: .afternoon      // inside the other person's working hours
        case .errand: .whenever
        case .idle:   .whenever
        }
    }

    private static func earliestBandWithRoom(_ minutes: Int, _ remaining: [Band: Int], preferred: Band) -> Band {
        if (remaining[preferred] ?? 0) >= minutes { return preferred }
        for band in Band.allCases.sorted() where band != .whenever {
            if (remaining[band] ?? 0) >= minutes { return band }
        }
        return .whenever
    }

    private static func split(_ tasks: [PlannableTask]) -> (idle: [PlannableTask], schedulable: [PlannableTask]) {
        var idle: [PlannableTask] = []
        var schedulable: [PlannableTask] = []
        for task in tasks {
            if task.type.isSchedulable { schedulable.append(task) } else { idle.append(task) }
        }
        return (idle, schedulable)
    }

    /// Due today, or overdue. Overdue work is still today's problem — it just
    /// never says so in red.
    private static func isDue(_ task: PlannableTask, on day: Date, calendar: Calendar) -> Bool {
        guard let due = task.due else { return false }
        return calendar.isDate(due, inSameDayAs: day) || due < calendar.startOfDay(for: day)
    }

    // MARK: - Ordering

    private static func byDueThenAge(_ a: PlannableTask, _ b: PlannableTask) -> Bool {
        switch (a.due, b.due) {
        case let (x?, y?) where x != y: return x < y
        default: return a.createdAt < b.createdAt
        }
    }

    /// Deep work first — it needs the room, and everything else can slot around
    /// it. Within a type, oldest first, so nothing starves at the bottom.
    private static func byTypeThenAge(_ a: PlannableTask, _ b: PlannableTask) -> Bool {
        let rank: [TaskType: Int] = [.deep: 0, .social: 1, .admin: 2, .errand: 3, .idle: 4]
        let left = rank[a.type] ?? 9
        let right = rank[b.type] ?? 9
        return left == right ? a.createdAt < b.createdAt : left < right
    }
}

extension Array {
    /// Splits into (matching, rest), preserving order in both.
    func partitioned(by predicate: (Element) -> Bool) -> ([Element], [Element]) {
        var matching: [Element] = []
        var rest: [Element] = []
        for element in self {
            if predicate(element) { matching.append(element) } else { rest.append(element) }
        }
        return (matching, rest)
    }
}
