import SwiftUI

@main
struct JawForgeApp: App {
    @State private var store = ScanStore()
    @State private var entitlements = Entitlements()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(entitlements)
                .preferredColorScheme(.light)   // neumorphism lives on a light surface
        }
    }
}
