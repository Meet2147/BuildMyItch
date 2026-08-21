import SwiftUI

@main
struct JawForgeApp: App {
    @State private var store = ScanStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(.dark)
        }
    }
}
