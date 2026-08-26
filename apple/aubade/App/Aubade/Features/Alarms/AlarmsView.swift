//  AlarmsView.swift
//  Two to four cards, not a table view. An alarm list is short by nature and
//  should look like objects, not rows in a database.

import SwiftUI
import SwiftData
import AubadeCore

public struct AlarmsView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Environment(\.nightness) private var nightness

    @Query(sort: [SortDescriptor(\Alarm.hour), SortDescriptor(\Alarm.minute)])
    private var alarms: [Alarm]

    @State private var editing: Alarm?
    @State private var showingCapability = false

    let store: AlarmStore

    public init(store: AlarmStore) { self.store = store }

    public var body: some View {
        PaletteReader { palette in
            ZStack {
                palette.ground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header(palette)

                        if alarms.isEmpty {
                            empty(palette)
                        } else {
                            ForEach(alarms) { alarm in
                                AlarmRow(alarm: alarm, palette: palette) {
                                    Task { await store.setEnabled(!alarm.isEnabled, on: alarm) }
                                } onTap: {
                                    editing = alarm
                                }
                            }
                        }

                        capabilityCard(palette)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 90)
                }

                VStack {
                    Spacer()
                    Button {
                        let alarm = store.add(hour: 7, minute: 0)
                        editing = alarm
                    } label: {
                        Label("New alarm", systemImage: "plus")
                            .font(.aubadeBody().weight(.semibold))
                            .foregroundStyle(palette.ink)
                    }
                    .buttonStyle(SoftButtonStyle(radius: 18))
                    .padding(.bottom, 18)
                }
            }
            .sheet(item: $editing) { alarm in
                AlarmEditor(alarm: alarm, store: store)
            }
        }
    }

    private func header(_ palette: Palette) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(subtitle).metaLabel(palette)
            Text("Alarms")
                .font(.aubadeTitle())
                .foregroundStyle(palette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var subtitle: String {
        let active = alarms.filter(\.isEnabled)
        guard !active.isEmpty else { return "None set" }
        let next = active.compactMap { $0.nextFire() }.min()
        guard let next,
              let countdown = active.first(where: { $0.nextFire() == next })?.countdownLabel()
        else { return "\(active.count) set" }
        return "Next in \(countdown)"
    }

    private func empty(_ palette: Palette) -> some View {
        Text("No alarms. Sleep in.")
            .font(.system(.title3, weight: .semibold))
            .foregroundStyle(palette.inkSoft)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 48)
    }

    /// What the app can honestly promise, in the app rather than buried in
    /// settings. An alarm clock that overstates itself is worse than one that
    /// admits its limits.
    private func capabilityCard(_ palette: Palette) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Before you rely on it").metaLabel(palette)
            Text(store.capabilityNote)
                .font(.aubadeBody())
                .foregroundStyle(palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .softSurface(.carved, radius: 18)
        .padding(.top, 10)
    }
}
