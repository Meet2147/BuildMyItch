//  Previews.swift
//  A believable day, so previews show the design under real load rather than
//  with two rows of lorem.

import SwiftUI
import SwiftData
import SillCore

#if DEBUG
enum PreviewData {

    @MainActor
    static func container() -> ModelContainer {
        let container = try! SillContainer.inMemory()
        let context = container.mainContext
        let store = TodoStore(context: context)
        let now = Date()

        store.capture("finish the Q3 deck before the Thursday review", now: now)
        store.capture("reply to Sam, expenses, chase the invoice", now: now)
        store.capture("pick up parcel", now: now)
        store.capture("gym at 7am", now: now)
        store.capture("water the plants every 5 days", now: now)
        store.capture("read the Ostrom paper", now: now)

        // Something old enough to be asked about.
        let old = Todo(title: "Look into that pension thing",
                       now: Calendar.current.date(byAdding: .day, value: -34, to: now) ?? now)
        context.insert(old)

        // And something already done, so the well isn't empty.
        let done = Todo(title: "Book the dentist", type: .admin, now: now)
        done.completedAt = now
        context.insert(done)

        return container
    }
}

#Preview("Today") {
    TodayView().modelContainer(PreviewData.container())
}

#Preview("Today · dark") {
    TodayView().modelContainer(PreviewData.container()).preferredColorScheme(.dark)
}

#Preview("Today · AX3 type") {
    TodayView()
        .modelContainer(PreviewData.container())
        .environment(\.dynamicTypeSize, .accessibility3)
}

/// The acceptance test for the whole design language: with every shadow gone,
/// nothing about this screen should become ambiguous.
#Preview("Today · relief off") {
    TodayView()
        .modelContainer(PreviewData.container())
        .softStoneFlattened()
}

#Preview("The pile") {
    PileView().modelContainer(PreviewData.container())
}
#endif
