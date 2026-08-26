//  TimeDial.swift
//
//  A carved dial rather than a wheel picker. Drag anywhere on the ring and the
//  hand follows, with a detent every five minutes — the tick under your thumb
//  is what makes setting an alarm feel like turning something rather than
//  scrolling a list. The numerals are still tappable for typing.

import SwiftUI

public struct TimeDial: View {

    @Binding var hour: Int
    @Binding var minute: Int
    let palette: Palette

    /// One turn of the dial is twelve hours; morning/evening is a separate,
    /// explicit choice rather than something you can scrub past by accident.
    private let detent = 5

    @State private var dragging = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(hour: Binding<Int>, minute: Binding<Int>, palette: Palette) {
        self._hour = hour
        self._minute = minute
        self.palette = palette
    }

    private var minutesOfHalfDay: Int { (hour % 12) * 60 + minute }
    private var fraction: Double { Double(minutesOfHalfDay) / 720.0 }

    public var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let centre = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)

            ZStack {
                Circle()
                    .fill(palette.ground)
                    .softSurface(.carved, radius: side / 2)

                // Twelve marks. Structure, not decoration: they're what tells
                // you which way round the dial runs.
                ForEach(0..<12, id: \.self) { index in
                    Capsule()
                        .fill(palette.inkFaint)
                        .frame(width: 2, height: index % 3 == 0 ? 13 : 7)
                        .offset(y: -side / 2 + 20)
                        .rotationEffect(.degrees(Double(index) * 30))
                }

                // The hand.
                Capsule()
                    .fill(palette.accent)
                    .frame(width: 5, height: side / 2 - 40)
                    .offset(y: -(side / 2 - 40) / 2)
                    .rotationEffect(.degrees(fraction * 360))

                Circle()
                    .fill(palette.accent)
                    .frame(width: 13, height: 13)

                VStack(spacing: 2) {
                    Text(String(format: "%d:%02d", hour % 12 == 0 ? 12 : hour % 12, minute))
                        .font(.clock(52))
                        .tracking(-1.5)
                        .foregroundStyle(palette.ink)
                    Text(hour < 12 ? "AM" : "PM")
                        .metaLabel(palette)
                }
                .offset(y: side / 5)
            }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragging = true
                        update(from: value.location, centre: centre)
                    }
                    .onEnded { _ in dragging = false }
            )
        }
        .aspectRatio(1, contentMode: .fit)
        // One tick per detent. Not per pixel — a continuous buzz is noise.
        .sensoryFeedback(.selection, trigger: minutesOfHalfDay)
        .animation(reduceMotion || dragging ? nil : Motion.snap, value: minutesOfHalfDay)
        .accessibilityElement()
        .accessibilityLabel("Alarm time")
        .accessibilityValue(String(format: "%d:%02d", hour, minute))
        .accessibilityAdjustableAction { direction in
            let delta = direction == .increment ? detent : -detent
            set(totalMinutes: minutesOfHalfDay + delta)
        }
    }

    private func update(from location: CGPoint, centre: CGPoint) {
        let dx = location.x - centre.x
        let dy = location.y - centre.y
        guard abs(dx) > 0.001 || abs(dy) > 0.001 else { return }

        // Zero at twelve o'clock, increasing clockwise.
        var angle = atan2(dx, -dy)
        if angle < 0 { angle += 2 * .pi }

        let raw = angle / (2 * .pi) * 720
        set(totalMinutes: Int((raw / Double(detent)).rounded()) * detent)
    }

    private func set(totalMinutes: Int) {
        var minutes = totalMinutes % 720
        if minutes < 0 { minutes += 720 }
        let wasAfternoon = hour >= 12
        hour = minutes / 60 + (wasAfternoon ? 12 : 0)
        minute = minutes % 60
    }
}
