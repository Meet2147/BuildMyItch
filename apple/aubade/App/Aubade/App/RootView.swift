//  RootView.swift

import SwiftUI
import SwiftData
import AubadeCore

public struct RootView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query private var alarms: [Alarm]

    @State private var tab: Tab = .alarms
    let store: AlarmStore
    let coordinator: RingingCoordinator

    enum Tab: String, CaseIterable, Identifiable {
        case alarms, night
        var id: String { rawValue }
        var title: String { self == .alarms ? "Alarms" : "Night" }
        var symbol: String { self == .alarms ? "alarm" : "moon.stars" }
    }

    public init(store: AlarmStore, coordinator: RingingCoordinator) {
        self.store = store
        self.coordinator = coordinator
    }

    public var body: some View {
        PaletteReader { palette in
            TabView(selection: $tab) {
                AlarmsView(store: store)
                    .tabItem { Label(Tab.alarms.title, systemImage: Tab.alarms.symbol) }
                    .tag(Tab.alarms)

                NightFaceView()
                    .tabItem { Label(Tab.night.title, systemImage: Tab.night.symbol) }
                    .tag(Tab.night)
            }
            .tint(palette.accent)
        }
        .fullScreenCover(isPresented: .init(
            get: { coordinator.isRinging },
            set: { if !$0 { coordinator.stop() } }
        )) {
            RingingView(alarm: ringingAlarm) {
                coordinator.stop()
            } onSnooze: { minutes in
                coordinator.stop()
                Task { await snooze(minutes: minutes) }
            }
        }
        .task {
            await store.requestAuthorization()
            await store.reconcileAll(alarms)
        }
        // The reconciliation loop is idempotent and cheap, so it runs on every
        // return to the foreground rather than being trusted to stay correct.
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await store.reconcileAll(alarms) }
        }
    }

    private var ringingAlarm: Alarm? {
        guard let id = coordinator.ringingAlarmID else { return nil }
        return alarms.first { $0.id == id }
    }

    private func snooze(minutes: Int) async {
        guard let alarm = ringingAlarm else { return }
        await store.snooze(alarm, minutes: minutes)
    }
}
