//  AlarmRow.swift

import SwiftUI
import AubadeCore

public struct AlarmRow: View {

    let alarm: Alarm
    let palette: Palette
    let onToggle: () -> Void
    let onTap: () -> Void

    public var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    if alarm.windowMinutes > 0 {
                        Text("by")
                            .font(.aubadeDetail())
                            .foregroundStyle(palette.inkFaint)
                    }
                    Text(alarm.clockLabel)
                        .font(.clock(38))
                        .tracking(-1)
                        .foregroundStyle(alarm.isEnabled ? palette.ink : palette.inkFaint)
                }
                Text(alarm.detailLabel)
                    .metaLabel(palette)
                    .opacity(alarm.isEnabled ? 1 : 0.6)
            }

            Spacer(minLength: 6)
            toggle
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .softSurface(.lifted, radius: 18)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(alarm.label ?? "Alarm at \(alarm.clockLabel)")
        .accessibilityValue(alarm.isEnabled ? "On, \(alarm.detailLabel)" : "Off")
        .accessibilityHint("Double tap to edit")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: alarm.isEnabled ? "Turn off" : "Turn on", onToggle)
    }

    /// A physical switch: the well is carved, the knob is lifted, and "off"
    /// reads as off without relying on colour alone.
    private var toggle: some View {
        Button(action: onToggle) {
            ZStack(alignment: alarm.isEnabled ? .trailing : .leading) {
                Capsule()
                    .fill(palette.ground)
                    .frame(width: 52, height: 30)
                    .softSurface(.carved, radius: 15)

                Circle()
                    .fill(alarm.isEnabled ? palette.accent : palette.inkFaint)
                    .frame(width: 22, height: 22)
                    .padding(.horizontal, 4)
            }
            .frame(width: 52, height: 30)
        }
        .buttonStyle(.plain)
        .accessibilityHidden(true)
        .animation(Motion.snap, value: alarm.isEnabled)
    }
}
