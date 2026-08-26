//  Motion.swift
//  One spring, three tunings. Everything in the app uses one of them — the
//  moment a screen invents its own timing, the app stops feeling like one thing.

import SwiftUI

public enum Motion {
    /// Controls, presses, chips.
    public static let snap = Animation.spring(response: 0.28, dampingFraction: 0.86)
    /// Rows, reorder, sheets. Anything with weight.
    public static let settle = Animation.spring(response: 0.44, dampingFraction: 0.82)
    /// Ambient. Slow enough that you can't watch it move.
    public static let drift = Animation.spring(response: 0.90, dampingFraction: 1.0)

    /// Nothing on an interactive path may exceed this.
    public static let interactiveCeiling: Double = 0.5
}
