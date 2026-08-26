//  AlarmKitScheduler.swift
//
//  The one that makes Aubade a real alarm clock — deliberately left as a stub.
//
//  AlarmKit is what lets a third-party app ring through the silent switch and
//  through a Focus, present the system alert UI, and put a Live Activity on
//  the Lock Screen and in the Dynamic Island. It is the entire reason this app
//  is possible at all.
//
//  It is stubbed rather than guessed at, because this file was written without
//  a Swift toolchain or an SDK to check against, and inventing plausible API
//  calls would produce a project that doesn't build. Everything above and
//  around it is real; this is the piece to write with the documentation open.
//
//  When you fill it in:
//
//  1. Add the authorization request and the usage-description key in Info.plist.
//  2. Build the alert presentation — the countdown, alert and paused states,
//     with a secondary button that opens the app so `RingingView` takes over
//     from the system UI.
//  3. Hand it the palette's audio; the ramp is `RampCurve`, already tested.
//  4. Set `breaksThroughSilentMode` to true and rewrite `capabilityNote` —
//     and only then, because that string is a promise to the user.
//  5. Delete `NotificationScheduler` from the composition root, not from disk;
//     it stays as the fallback when authorization is refused.
//
//  Prove it on a device before anything else. If AlarmKit doesn't do what we
//  need, that has to be discovered in week one, not month three.

import Foundation
import AubadeCore

public struct AlarmKitScheduler: AlarmScheduling {

    public init() {}

    public var breaksThroughSilentMode: Bool { true }

    public var capabilityNote: String {
        "Aubade rings through silent mode and through a Focus."
    }

    public func requestAuthorization() async -> AlarmAuthorization {
        .denied
    }

    public func schedule(_ request: AlarmRequest) async throws {
        throw AlarmSchedulingError.unavailable("AlarmKit is not wired up yet — see AlarmKitScheduler.swift")
    }

    public func cancel(alarmID: UUID) async {}
    public func cancelAll() async {}
}
