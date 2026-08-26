//  SillContainer.swift
//  One place that knows how the store is built, so previews, tests and the app
//  can't drift apart.

import Foundation
import SwiftData
import SillCore

public enum SillContainer {

    public static let schema = Schema([Todo.self])

    /// The real store. CloudKit mirroring is switched on by the entitlement
    /// rather than in code — see `architecture/SYNC.md`.
    public static func live() throws -> ModelContainer {
        try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        )
    }

    public static func inMemory() throws -> ModelContainer {
        try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
    }
}
