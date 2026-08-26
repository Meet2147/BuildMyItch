//  AubadeContainer.swift

import Foundation
import SwiftData

public enum AubadeContainer {

    public static let schema = Schema([Alarm.self])

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
