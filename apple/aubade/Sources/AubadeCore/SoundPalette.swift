//  SoundPalette.swift
//
//  Generated rather than looped, so there's no seam and no moment you learn to
//  recognise as "the bit before it gets loud". A five-minute wake is a handful
//  of parameters rather than five minutes of audio.

import Foundation

public enum SoundPalette: String, CaseIterable, Codable, Sendable {
    case glass, ember, rainfall, bellGarden, lowStrings, tide

    public var title: String {
        switch self {
        case .glass:      "Glass"
        case .ember:      "Ember"
        case .rainfall:   "Rainfall"
        case .bellGarden: "Bell Garden"
        case .lowStrings: "Low Strings"
        case .tide:       "Tide"
        }
    }

    /// One line, written, that says what it sounds like without being florid.
    public var blurb: String {
        switch self {
        case .glass:      "Struck glass, long decay"
        case .ember:      "Warm, low, a slow pulse"
        case .rainfall:   "Rain that gets closer"
        case .bellGarden: "Small bells, no pattern"
        case .lowStrings: "One chord, opening"
        case .tide:       "Breath-paced swells"
        }
    }

    /// Root frequency in Hz for the fundamental voice.
    public var root: Double {
        switch self {
        case .glass:      523.25   // C5
        case .ember:      110.00   // A2
        case .rainfall:   220.00
        case .bellGarden: 659.25   // E5
        case .lowStrings: 146.83   // D3
        case .tide:       98.00    // G2
        }
    }

    /// Harmonic ratios for the voices that enter as the ramp proceeds.
    public var voices: [Double] {
        switch self {
        case .glass:      [1, 2, 3, 4.2]
        case .ember:      [1, 2, 3, 5]
        case .rainfall:   [1, 1.5, 2.25, 3]
        case .bellGarden: [1, 2.76, 5.4, 8.9]     // inharmonic, like real bells
        case .lowStrings: [1, 1.5, 2, 3]
        case .tide:       [1, 2, 2.5, 4]
        }
    }

    /// Seconds for one breath cycle in the layers that pulse.
    public var breathPeriod: Double {
        switch self {
        case .tide:       9.0
        case .ember:      7.0
        default:          0
        }
    }
}
