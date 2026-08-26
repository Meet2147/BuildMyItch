//  Previews.swift
//  A believable nightstand, so the design gets judged under real conditions
//  rather than with one alarm and no state.

import SwiftUI
import SwiftData
import AubadeCore

#if DEBUG

/// A scheduler that does nothing, so previews never touch the notification
/// system and never ask for permission.
struct InertScheduler: AlarmScheduling {
    var breaksThroughSilentMode: Bool { false }
    var capabilityNote: String {
        "Preview only — nothing is actually scheduled."
    }
    func requestAuthorization() async -> AlarmAuthorization { .limited }
    func schedule(_ request: AlarmRequest) async throws {}
    func cancel(alarmID: UUID) async {}
    func cancelAll() async {}
}

@MainActor
enum PreviewData {

    static func container() -> ModelContainer {
        let container = try! AubadeContainer.inMemory()
        let context = container.mainContext

        context.insert(Alarm(hour: 6, minute: 40, windowMinutes: 20,
                             days: .workweek, palette: .ember))
        context.insert(Alarm(hour: 7, minute: 15, days: .weekend, palette: .tide))
        context.insert(Alarm(label: "Flight", hour: 5, minute: 30,
                             palette: .glass, isEnabled: false))
        return container
    }

    static func store(_ container: ModelContainer) -> AlarmStore {
        AlarmStore(context: container.mainContext, scheduler: InertScheduler())
    }
}

#Preview("Alarms") {
    let container = PreviewData.container()
    return AlarmsView(store: PreviewData.store(container))
        .modelContainer(container)
}

#Preview("Alarms · dark") {
    let container = PreviewData.container()
    return AlarmsView(store: PreviewData.store(container))
        .modelContainer(container)
        .preferredColorScheme(.dark)
}

/// The acceptance test for the design language: with every shadow gone,
/// nothing here should become ambiguous — including which alarms are on.
#Preview("Alarms · relief off") {
    let container = PreviewData.container()
    return AlarmsView(store: PreviewData.store(container))
        .modelContainer(container)
        .softStoneFlattened()
}

#Preview("Editor") {
    let container = PreviewData.container()
    let alarm = Alarm(hour: 6, minute: 40, windowMinutes: 20, days: .workweek)
    container.mainContext.insert(alarm)
    return AlarmEditor(alarm: alarm, store: PreviewData.store(container))
        .modelContainer(container)
}

#Preview("Ringing") {
    RingingView(alarm: Alarm(hour: 6, minute: 40, windowMinutes: 20),
                onDismiss: {}, onSnooze: { _ in })
}

#Preview("Night face") {
    NightFaceView().modelContainer(PreviewData.container())
}
#endif
