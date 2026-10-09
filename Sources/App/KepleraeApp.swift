import SwiftUI

@main
struct KepleraeApp: App {
    @StateObject private var catalog = CatalogStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(catalog)
        }
    }
}
