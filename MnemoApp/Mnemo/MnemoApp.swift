import SwiftUI
import SwiftData
import MnemoMemory
import MnemoSecurity
import MnemoIntelligence

@main
struct MnemoApp: App {

    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(appState)
                .task {
                    await appState.initialise()
                }
        }
        .modelContainer(MemoryStore.shared.container)
    }
}
