import SwiftUI
import SwiftData
import MnemoMemory
import MnemoSecurity
import MnemoIntelligence

@main
struct MnemoApp: App {

    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(appState)
                .task {
                    await appState.initialise()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    appState.handleScenePhase(newPhase)
                }
        }
        .modelContainer(MemoryStore.shared.container)
    }
}
