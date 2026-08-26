//  NightFaceView.swift
//
//  The reason Aubade earns its place on the nightstand: at 3am it's a
//  genuinely good clock. Amber ink on near-black, dimmed until it's barely
//  there, tap anywhere to brighten for five seconds.

import SwiftUI
import SwiftData
import AubadeCore

public struct NightFaceView: View {

    @Query(sort: [SortDescriptor(\Alarm.hour), SortDescriptor(\Alarm.minute)])
    private var alarms: [Alarm]

    @State private var now = Date()
    @State private var bright = false
    @State private var dimTask: Task<Void, Never>?

    public init() {}

    public var body: some View {
        PaletteReader { palette in
            ZStack {
                palette.ground.ignoresSafeArea()

                VStack(spacing: 14) {
                    Text(now.formatted(.dateTime.hour().minute()))
                        .font(.clock(88))
                        .tracking(-3)
                        .foregroundStyle(palette.ink)

                    if let next = countdown {
                        Text("Alarm in \(next)")
                            .metaLabel(palette)
                    } else {
                        Text("No alarm set")
                            .metaLabel(palette)
                    }
                }
                // Barely visible by default. Anything brighter at 3am costs you
                // twenty minutes of night vision.
                .opacity(bright ? 1.0 : 0.34)
                .animation(.easeInOut(duration: bright ? 0.2 : 1.4), value: bright)
            }
            .contentShape(Rectangle())
            .onTapGesture { brighten() }
        }
        .nightFace()
        .task {
            while !Task.isCancelled {
                now = Date()
                try? await Task.sleep(for: .seconds(10))
            }
        }
        .onDisappear { dimTask?.cancel() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Night face")
        .accessibilityValue(now.formatted(.dateTime.hour().minute()))
    }

    /// The soonest alarm, not the earliest clock time — 6:40 tomorrow beats
    /// 5:30 next Saturday.
    private var countdown: String? {
        alarms
            .filter(\.isEnabled)
            .compactMap { alarm -> (Date, String)? in
                guard let next = alarm.nextFire(after: now),
                      let label = alarm.countdownLabel(from: now) else { return nil }
                return (next, label)
            }
            .min { $0.0 < $1.0 }?
            .1
    }

    private func brighten() {
        bright = true
        dimTask?.cancel()
        dimTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            await MainActor.run { bright = false }
        }
    }
}
