//  SillApp.swift

import SwiftUI
import SwiftData

@main
struct SillApp: App {

    private let container: ModelContainer

    init() {
        do {
            container = try SillContainer.live()
        } catch {
            // A store that won't open is not recoverable, and pretending
            // otherwise means silently losing someone's list.
            fatalError("Could not open the Sill store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
        #if os(macOS)
        .defaultSize(width: 460, height: 720)
        .commands { SillCommands() }
        #endif
    }
}

#if os(macOS)
struct SillCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Capture…") { NotificationCenter.default.post(name: .sillFocusCapture, object: nil) }
                .keyboardShortcut("n", modifiers: .command)
        }
    }
}
#endif

extension Notification.Name {
    static let sillFocusCapture = Notification.Name("sill.focusCapture")
}
