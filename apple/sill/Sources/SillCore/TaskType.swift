//  TaskType.swift
//  The load-bearing idea in Sill: tasks are classified by the *shape of
//  attention* they need, not by a priority the user assigns.
//
//  Priority flags fail because everything becomes P1. "Needs an uninterrupted
//  hour" is observable and doesn't inflate.

import Foundation

public enum TaskType: String, CaseIterable, Codable, Sendable {
    /// Needs an uninterrupted stretch. Scheduled into the focus band, max two a day.
    case deep
    /// Short, boring, low stakes. Batched into one block.
    case admin
    /// Requires being somewhere. Grouped, never time-boxed.
    case errand
    /// Requires another person. Kept inside working hours.
    case social
    /// Doable in a queue. Surfaced on the widget, never scheduled.
    case idle

    public var title: String {
        switch self {
        case .deep:   "Deep"
        case .admin:  "Admin"
        case .errand: "Errand"
        case .social: "Social"
        case .idle:   "Idle"
        }
    }

    /// SF Symbol. Chosen to read at 13pt without colour.
    public var symbolName: String {
        switch self {
        case .deep:   "circle.hexagongrid"
        case .admin:  "tray"
        case .errand: "figure.walk"
        case .social: "bubble.left.and.bubble.right"
        case .idle:   "leaf"
        }
    }

    /// What we assume when the sentence gave us nothing to go on.
    /// Deliberately generous — under-estimating is what makes a day plan lie.
    public var defaultEstimate: Int {
        switch self {
        case .deep:   60
        case .admin:  15
        case .errand: 30
        case .social: 10
        case .idle:   15
        }
    }

    /// Idle work never gets a slot in the day. That's the whole point of it.
    public var isSchedulable: Bool { self != .idle }

    /// How many of these we're willing to put in one day. `nil` = no cap.
    public var dailyCap: Int? { self == .deep ? 2 : nil }
}
