//  TodoStore.swift
//  Everything that changes a task goes through here, so the rules about
//  completion, recurrence and letting go live in one place rather than being
//  re-implemented in each view.

import Foundation
import SwiftData
import SillCore

@Observable
public final class TodoStore {

    private let context: ModelContext
    private let calendar: Calendar

    public init(context: ModelContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
    }

    // MARK: - Capture

    /// One line in, one or more tasks out. Returns them so the capture field
    /// can show what it made — the user should always see the result of a
    /// guess, never discover it later in a list.
    @discardableResult
    public func capture(_ text: String, now: Date = Date(), sourceURL: URL? = nil) -> [Todo] {
        let parser = CaptureParser(now: now, calendar: calendar)
        let parsed = parser.parse(text)
        let todos = parsed.map { make($0, now: now, sourceURL: sourceURL) }
        for todo in todos { context.insert(todo) }
        return todos
    }

    public func make(_ parsed: ParsedTask, now: Date = Date(), sourceURL: URL? = nil) -> Todo {
        Todo(
            title: parsed.title,
            type: parsed.type,
            estimateMinutes: parsed.estimateMinutes,
            estimateWasStated: parsed.estimateWasStated,
            due: parsed.due,
            plannedDay: parsed.day,
            pinnedBand: parsed.band,
            recurrence: parsed.recurrence,
            sourceURL: sourceURL,
            now: now
        )
    }

    // MARK: - Completion

    public func complete(_ todo: Todo, now: Date = Date()) {
        guard todo.isOpen else { return }
        todo.completedAt = now
        todo.modifiedAt = now

        // Recurrence is *after completion*, so the next one is born here rather
        // than sitting in the future waiting to go overdue.
        if let recurrence = todo.recurrence, let next = recurrence.nextDay(after: now, calendar: calendar) {
            let follow = Todo(
                title: todo.title,
                type: todo.type,
                estimateMinutes: todo.estimateMinutes,
                estimateWasStated: todo.estimateWasStated,
                plannedDay: next,
                pinnedBand: todo.pinnedBand,
                recurrence: recurrence,
                sourceURL: todo.sourceURL,
                now: now
            )
            context.insert(follow)
        }
    }

    public func uncomplete(_ todo: Todo, now: Date = Date()) {
        todo.completedAt = nil
        todo.modifiedAt = now
    }

    // MARK: - Letting go

    /// Not deleting. The task stops appearing anywhere you'd have to look at
    /// it, and stays recoverable. Silent data loss is the one outcome a
    /// personal list can't survive.
    public func letGo(_ todo: Todo, now: Date = Date()) {
        todo.letGoAt = now
        todo.askedAt = now
        todo.modifiedAt = now
    }

    public func keep(_ todo: Todo, now: Date = Date()) {
        todo.askedAt = now
        todo.modifiedAt = now
    }

    public func restore(_ todo: Todo, now: Date = Date()) {
        todo.letGoAt = nil
        todo.askedAt = nil
        todo.modifiedAt = now
    }

    // MARK: - Editing

    public func move(_ todo: Todo, to band: Band, on day: Date, now: Date = Date()) {
        todo.pinnedBand = band
        todo.plannedDay = calendar.startOfDay(for: day)
        todo.modifiedAt = now
    }

    public func schedule(_ todo: Todo, on day: Date?, now: Date = Date()) {
        todo.plannedDay = day.map { calendar.startOfDay(for: $0) }
        todo.modifiedAt = now
    }

    public func setType(_ type: TaskType, on todo: Todo, now: Date = Date()) {
        todo.type = type
        if !todo.estimateWasStated { todo.estimateMinutes = type.defaultEstimate }
        todo.modifiedAt = now
    }

    public func setEstimate(_ minutes: Int, on todo: Todo, now: Date = Date()) {
        todo.estimateMinutes = max(1, minutes)
        todo.estimateWasStated = true
        todo.modifiedAt = now
    }
}
