//  BreatheRing.swift
//
//  Not a maths problem, not a barcode to photograph.
//
//  Hold the ring and it fills over eight seconds while a slow haptic paces an
//  inhale. Let go early and it drains. You can't do this in your sleep — it
//  needs sustained attention — but it's calm rather than punitive, and it
//  leaves you fractionally more awake instead of furious.

import SwiftUI

public struct BreatheRing: View {

    let onComplete: () -> Void

    public static let holdDuration: Double = 8

    @State private var progress: Double = 0
    @State private var holding = false
    @State private var countdown: Task<Void, Never>?
    @State private var finished = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(onComplete: @escaping () -> Void) { self.onComplete = onComplete }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.26), lineWidth: 6)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color(hex: 0xFFF1DC), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: 0xFFF1DC))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 26)
        }
        .frame(width: 168, height: 168)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in start() }
                .onEnded { _ in cancel() }
        )
        .sensoryFeedback(.impact(weight: .light), trigger: holding) { _, now in now }
        .sensoryFeedback(.success, trigger: finished) { _, done in done }
        .accessibilityElement()
        .accessibilityLabel("Hold to wake")
        .accessibilityHint("Press and hold for eight seconds to dismiss the alarm")
        .accessibilityAddTraits(.isButton)
        // Someone using VoiceOver shouldn't have to hold a ring for eight
        // seconds to turn off an alarm.
        .accessibilityAction { complete() }
        .onDisappear { countdown?.cancel() }
    }

    private var label: String {
        if finished { return "Good morning" }
        return holding ? "Keep holding" : "Hold to wake"
    }

    private func start() {
        guard !holding, !finished else { return }
        holding = true
        withAnimation(reduceMotion ? nil : .linear(duration: Self.holdDuration)) {
            progress = 1
        }
        countdown = Task {
            try? await Task.sleep(for: .seconds(Self.holdDuration))
            guard !Task.isCancelled else { return }
            await MainActor.run { complete() }
        }
    }

    private func cancel() {
        guard !finished else { return }
        countdown?.cancel()
        countdown = nil
        holding = false
        withAnimation(.easeOut(duration: 0.55)) { progress = 0 }
    }

    private func complete() {
        guard !finished else { return }
        finished = true
        holding = false
        progress = 1
        onComplete()
    }
}
