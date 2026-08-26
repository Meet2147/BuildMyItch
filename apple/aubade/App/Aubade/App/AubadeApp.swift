//  AubadeApp.swift

import SwiftUI
import SwiftData

@main
struct AubadeApp: App {

    private let container: ModelContainer
    @State private var store: AlarmStore
    @State private var coordinator = RingingCoordinator()

    init() {
        do {
            container = try AubadeContainer.live()
        } catch {
            fatalError("Could not open the Aubade store: \(error)")
        }
        // The composition root, and the only place the scheduler is chosen.
        // Swapping NotificationScheduler for AlarmKitScheduler is this line.
        _store = State(initialValue: AlarmStore(
            context: container.mainContext,
            scheduler: NotificationScheduler()
        ))
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store, coordinator: coordinator)
                .task { coordinator.install() }
        }
        .modelContainer(container)
    }
}
