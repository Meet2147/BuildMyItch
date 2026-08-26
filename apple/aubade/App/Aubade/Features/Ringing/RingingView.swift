//  RingingView.swift
//
//  Nothing on this screen but the time, the ring, and one way out. The first
//  thing someone sees each day shouldn't be a dashboard.
//
//  With AlarmKit wired, the system alert opens this via its secondary button.
//  Until then it's reachable from a notification tap and from the previews.

import SwiftUI
import AubadeCore

public struct RingingView: View {

    let alarm: Alarm?
    let onDismiss: () -> Void
    let onSnooze: (Int) -> Void

    /// How far through the ramp we are — drives both the light and the sound.
    @State private var progress: Double = 0.35
    @State private var snoozes = 0
    @State private var now = Date()

    private let curve = RampCurve()

    public init(alarm: Alarm?, onDismiss: @escaping () -> Void, onSnooze: @escaping (Int) -> Void) {
        self.alarm = alarm
        self.onDismiss = onDismiss
        self.onSnooze = onSnooze
    }

    public var body: some View {
        ZStack {
            SunriseGradient(progress: progress)

            VStack(spacing: 30) {
                Spacer()

                VStack(spacing: 10) {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundStyle(Color(hex: 0xFFEED7).opacity(0.8))

                    Text(now.formatted(.dateTime.hour().minute()))
                        .font(.clock(72))
                        .tracking(-2)
                        .foregroundStyle(Color(hex: 0xFFF3E2))
                        .shadow(color: Color(hex: 0x3C1A00).opacity(0.4), radius: 22, y: 2)
                }

                BreatheRing(onComplete: onDismiss)

                if SnoozeLadder.isAvailable(afterSnoozes: snoozes) {
                    Button {
                        let minutes = SnoozeLadder.minutes(afterSnoozes: snoozes)
                        snoozes += 1
                        onSnooze(minutes)
                    } label: {
                        Text("Snooze · \(SnoozeLadder.minutes(afterSnoozes: snoozes)) min")
                            .font(.system(size: 12, weight: .medium))
                            .tracking(1.6)
                            .textCase(.uppercase)
                            .foregroundStyle(Color(hex: 0xFFEED7).opacity(0.75))
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                } else {
                    // Four snoozes in, the alarm has failed. Saying so is more
                    // use than a fifth five minutes.
                    Text("That's the last one")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundStyle(Color(hex: 0xFFEED7).opacity(0.5))
                        .padding(.vertical, 12)
                }

                Spacer().frame(height: 24)
            }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .task {
            // The ramp keeps climbing while the screen is up.
            while !Task.isCancelled {
                now = Date()
                progress = min(1, progress + 0.01)
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private var subtitle: String {
        guard let alarm, alarm.windowMinutes > 0 else { return "Alarm" }
        return "Light sleep · by \(alarm.clockLabel)"
    }
}
