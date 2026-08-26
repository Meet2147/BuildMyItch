//  SunriseGradient.swift
//  The light half of the wake. Screen brightness ramps alongside it; a phone
//  is a small wake light, but at 20cm on a nightstand it does real work.

import SwiftUI

public struct SunriseGradient: View {

    /// 0 at the start of the ramp, 1 at the hard time.
    var progress: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(progress: Double) { self.progress = progress }

    public var body: some View {
        let p = max(0, min(1, progress))

        ZStack {
            Color(hex: 0x2A2320).ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(hex: 0xE8A24C).opacity(0.25 + 0.75 * p),
                    Color(hex: 0xC2743C).opacity(0.20 + 0.65 * p),
                    Color(hex: 0x6A4634).opacity(0.35 + 0.35 * p),
                    .clear,
                ],
                center: UnitPoint(x: 0.5, y: 1.18),
                startRadius: 0,
                endRadius: 620
            )
            .ignoresSafeArea()

            // A slow breath in the glow — under Reduce Motion it simply holds.
            if !reduceMotion {
                TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    let breath = 0.5 + 0.5 * sin(t / 4.5)
                    RadialGradient(
                        colors: [Color(hex: 0xFFD696).opacity(0.28 * breath * (0.4 + 0.6 * p)), .clear],
                        center: UnitPoint(x: 0.5, y: 1.1),
                        startRadius: 0,
                        endRadius: 420
                    )
                    .ignoresSafeArea()
                }
            }
        }
    }
}
