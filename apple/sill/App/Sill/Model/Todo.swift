//  Todo.swift
//
//  The whole data model. One flat entity, no relationships, no projects, no
//  tags, no priority field. A task with eight subtasks is eight tasks.
//
//  Named `Todo` rather than `Task` on purpose: `Task` is Swift concurrency's,
//  and shadowing it inside the module is a decade of small papercuts.
//
//  Shaped for CloudKit mirroring from day one — every property is optional or
//  defaulted and there are no unique constraints, because discovering those
//  rules at integration time means rewriting the model.

import Foundation
import SwiftData
import SillCore

@Model
public final class Todo {

    public var id: UUID = UUID()
    public var title: String = ""
    public var note: String?

    public var typeRaw: String = TaskType.admin.rawValue
    public var estimateMinutes: Int = 15
    /// False when the estimate is our guess rather than the user's. Guesses
    /// render lighter than decisions.
    public var estimateWasStated: Bool = false

    /// A real deadline. Rare, and the only thing that can jump the queue.
    public var due: Date?
    /// The day this is meant for. `nil` means it's in the Pile.
    public var plannedDay: Date?
    /// Set only when the user drags it into a band themselves.
    public var pinnedBandRaw: String?

    public var completedAt: Date?
    /// Soft delete. "Let go" is not "deleted" — it's recoverable, and it's the
    /// mechanism that stops the backlog becoming a debt.
    public var letGoAt: Date?
    /// The last time we asked "still real?", so we only ask once.
    public var askedAt: Date?

    public var recurrenceData: Data?
    /// Back-link from the share sheet: the mail message, page or note it came from.
    public var sourceURLString: String?

    public var createdAt: Date = Date.distantPast
    public var modifiedAt: Date = Date.distantPast

    public init(
        id: UUID = UUID(),
        title: String,
        type: TaskType = .admin,
        estimateMinutes: Int = 15,
        estimateWasStated: Bool = false,
        due: Date? = nil,
        plannedDay: Date? = nil,
        pinnedBand: Band? = nil,
        recurrence: Recurrence? = nil,
        sourceURL: URL? = nil,
        now: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.typeRaw = type.rawValue
        self.estimateMinutes = estimateMinutes
        self.estimateWasStated = estimateWasStated
        self.due = due
        self.plannedDay = plannedDay
        self.pinnedBandRaw = pinnedBand?.rawValue
        self.recurrenceData = recurrence.flatMap { try? JSONEncoder().encode($0) }
        self.sourceURLString = sourceURL?.absoluteString
        self.createdAt = now
        self.modifiedAt = now
    }

    // MARK: - Typed accessors
    //
    // Enums are stored as raw strings rather than as Codable values. It costs
    // these six lines and buys a schema that survives adding a case later.

    public var type: TaskType {
        get { TaskType(rawValue: typeRaw) ?? .admin }
        set { typeRaw = newValue.rawValue }
    }

    public var pinnedBand: Band? {
        get { pinnedBandRaw.flatMap(Band.init(rawValue:)) }
        set { pinnedBandRaw = newValue?.rawValue }
    }

    public var recurrence: Recurrence? {
        get { recurrenceData.flatMap { try? JSONDecoder().decode(Recurrence.self, from: $0) } }
        set { recurrenceData = newValue.flatMap { try? JSONEncoder().encode($0) } }
    }

    public var sourceURL: URL? {
        get { sourceURLString.flatMap(URL.init(string:)) }
        set { sourceURLString = newValue?.absoluteString }
    }

    // MARK: - State

    public var isDone: Bool { completedAt != nil }
    public var isLetGo: Bool { letGoAt != nil }
    public var isOpen: Bool { completedAt == nil && letGoAt == nil }

    public func daysOld(now: Date = Date(), calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: createdAt),
                                to: calendar.startOfDay(for: now)).day ?? 0
    }

    /// How much an old task fades, 0 (fresh) to 1 (about to be asked about).
    /// Old work gets quieter, never louder. Nothing in Sill ever goes red.
    public func quietness(now: Date = Date(), calendar: Calendar = .current) -> Double {
        guard isOpen, due == nil else { return 0 }
        let days = Double(daysOld(now: now, calendar: calendar))
        return min(1.0, max(0.0, (days - 7) / 23))     // starts fading at a week
    }

    /// At thirty days we ask, once, on a quiet card: *still real?*
    public func shouldAskStillReal(now: Date = Date(), calendar: Calendar = .current) -> Bool {
        isOpen && due == nil && askedAt == nil && daysOld(now: now, calendar: calendar) >= 30
    }

    // MARK: - Planning bridge

    public func plannable() -> PlannableTask {
        PlannableTask(
            id: id,
            type: type,
            estimateMinutes: estimateMinutes,
            due: due,
            pinned: pinnedBand,
            createdAt: createdAt
        )
    }
}
