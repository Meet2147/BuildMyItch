//  AlarmScheduling.swift
//
//  The seam.
//
//  Everything platform-specific and frightening about an alarm clock lives
//  behind this protocol: whether it can ring through silent mode, whether a
//  Focus suppresses it, what the OS shows on the Lock Screen. Swapping the
//  notification implementation for AlarmKit is one file, and that file is
//  where "does this actually wake someone" gets proven on a device.

import Foundation
import AubadeCore

public enum AlarmAuthorization: String, Sendable {
    case unknown
    case granted
    case denied
    /// Granted, but the OS won't let us break through silent mode or a Focus.
    case limited

    public var canRing: Bool { self == .granted || self == .limited }
}

public struct AlarmRequest: Sendable, Equatable {
    /// Identifies this batch of pending notifications, so it can be cancelled.
    public var id: UUID
    /// The alarm the user actually set. A snooze is scheduled under its own
    /// `id` so it doesn't clobber the repeating alarm, but it still has to
    /// tell the ringing screen which alarm it came from.
    public var originAlarmID: UUID
    public var title: String
    /// Concrete instants. Computed locally and handed over, so nothing about
    /// firing depends on a network or a sync.
    public var occurrences: [Date]
    public var palette: SoundPalette
    public var repeats: Bool

    public init(
        id: UUID,
        originAlarmID: UUID? = nil,
        title: String,
        occurrences: [Date],
        palette: SoundPalette,
        repeats: Bool
    ) {
        self.id = id
        self.originAlarmID = originAlarmID ?? id
        self.title = title
        self.occurrences = occurrences
        self.palette = palette
        self.repeats = repeats
    }
}

public enum AlarmSchedulingError: Error {
    case notAuthorized
    case unavailable(String)
}

public protocol AlarmScheduling: Sendable {
    func requestAuthorization() async -> AlarmAuthorization
    func schedule(_ request: AlarmRequest) async throws
    func cancel(alarmID: UUID) async
    func cancelAll() async

    /// What this implementation can honestly promise. Shown verbatim in
    /// Settings — an alarm app that overstates itself is worse than one that
    /// admits its limits.
    var capabilityNote: String { get }
    var breaksThroughSilentMode: Bool { get }
}
