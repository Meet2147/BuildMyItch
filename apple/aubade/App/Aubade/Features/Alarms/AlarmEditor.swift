//  AlarmEditor.swift

import SwiftUI
import AubadeCore

public struct AlarmEditor: View {

    @Bindable var alarm: Alarm
    let store: AlarmStore

    @Environment(\.dismiss) private var dismiss

    public init(alarm: Alarm, store: AlarmStore) {
        self.alarm = alarm
        self.store = store
    }

    public var body: some View {
        PaletteReader { palette in
            ZStack {
                palette.ground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 26) {
                        TimeDial(hour: $alarm.hour, minute: $alarm.minute, palette: palette)
                            .frame(maxWidth: 320)
                            .padding(.top, 14)

                        meridiem(palette)
                        window(palette)
                        days(palette)
                        palettes(palette)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 34)
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button("Delete", role: .destructive) {
                        Task { await store.delete(alarm); dismiss() }
                    }
                    .buttonStyle(SoftButtonStyle(resting: .lifted, radius: 14))
                    .foregroundStyle(palette.inkSoft)

                    Button("Done") {
                        Task { await store.update(alarm) { _ in }; dismiss() }
                    }
                    .buttonStyle(SoftButtonStyle(radius: 14))
                    .foregroundStyle(palette.ink)
                }
                .padding(16)
                .background(palette.ground)
            }
        }
    }

    // MARK: - Sections

    private func section<Content: View>(
        _ title: String, _ palette: Palette, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).metaLabel(palette)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func meridiem(_ palette: Palette) -> some View {
        section("Half of the day", palette) {
            HStack(spacing: 10) {
                chip("Morning", on: alarm.hour < 12, palette) {
                    if alarm.hour >= 12 { alarm.hour -= 12 }
                }
                chip("Evening", on: alarm.hour >= 12, palette) {
                    if alarm.hour < 12 { alarm.hour += 12 }
                }
            }
        }
    }

    /// The idea the whole app rests on, so it gets a section of its own and a
    /// sentence explaining it rather than a bare stepper.
    private func window(_ palette: Palette) -> some View {
        section("Wake window", palette) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 9) {
                    ForEach([0, 10, 20, 30], id: \.self) { minutes in
                        chip(minutes == 0 ? "Exact" : "\(minutes)m",
                             on: alarm.windowMinutes == minutes, palette) {
                            alarm.windowMinutes = minutes
                        }
                    }
                }
                Text(alarm.windowMinutes == 0
                     ? "Rings at exactly \(alarm.clockLabel)."
                     : "Rings at the best moment in the \(alarm.windowMinutes) minutes before \(alarm.clockLabel) — never later.")
                    .font(.aubadeDetail())
                    .foregroundStyle(palette.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func days(_ palette: Palette) -> some View {
        section("Repeat", palette) {
            HStack(spacing: 7) {
                ForEach(Array(dayOptions.enumerated()), id: \.offset) { _, option in
                    chip(option.label, on: alarm.days.contains(option.day), palette) {
                        if alarm.days.contains(option.day) {
                            alarm.days.subtract(option.day)
                        } else {
                            alarm.days.formUnion(option.day)
                        }
                    }
                }
            }
        }
    }

    private var dayOptions: [(label: String, day: Weekdays)] {
        [("M", .monday), ("T", .tuesday), ("W", .wednesday), ("T", .thursday),
         ("F", .friday), ("S", .saturday), ("S", .sunday)]
    }

    private func palettes(_ palette: Palette) -> some View {
        section("Sound", palette) {
            VStack(spacing: 8) {
                ForEach(SoundPalette.allCases, id: \.self) { option in
                    Button {
                        alarm.palette = option
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.title)
                                    .font(.aubadeBody().weight(alarm.palette == option ? .semibold : .regular))
                                    .foregroundStyle(palette.ink)
                                Text(option.blurb)
                                    .font(.aubadeDetail())
                                    .foregroundStyle(palette.inkFaint)
                            }
                            Spacer()
                            if alarm.palette == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(palette.accent)
                            }
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .softSurface(alarm.palette == option ? .carved : .lifted, radius: 14)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// Selection is carried by weight and a glyph, never by relief alone —
    /// flatten every shadow and you can still see what's chosen.
    private func chip(_ title: String, on: Bool, _ palette: Palette, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.aubadeBody().weight(on ? .semibold : .regular))
                .foregroundStyle(on ? palette.accent : palette.inkSoft)
                .frame(minWidth: 42)
                .padding(.horizontal, 13)
                .padding(.vertical, 10)
                .softSurface(on ? .carved : .lifted, radius: 12)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }
}
