import SwiftUI
import SwiftData
import BackgroundTasks
import MnemoMemory
import MnemoSecurity
import MnemoIntelligence

@main
struct MnemoApp: App {

    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase
    private let backgroundRefreshIdentifier = "com.thinkact.mnemo.backgroundRefresh"

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(appState)
                .task {
                    await appState.initialise()
                    scheduleNextBackgroundRefresh()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    appState.handleScenePhase(newPhase)
                }
        }
        .backgroundTask(.appRefresh(backgroundRefreshIdentifier)) {
            await performBackgroundRefresh()
        }
        .modelContainer(MemoryStore.shared.container)
    }

    @MainActor
    private func performBackgroundRefresh() async {
        scheduleNextBackgroundRefresh()

        let context = MemoryStore.shared.container.mainContext
        do {
            let records = try MemoryCRUD.fetchAll(in: context)
            let engine = PersistenceEngine()
            let updates = engine.evaluateAll(records: records)
            for update in updates {
                guard let record = records.first(where: { $0.id == update.memoryId }) else { continue }
                guard abs(record.persistenceScore - update.newScore) > 0.0001 else { continue }
                try? MemoryCRUD.updatePersistenceScore(
                    id: update.memoryId,
                    score: update.newScore,
                    state: update.newState,
                    in: context
                )
            }
        } catch {
            // Background tasks must not throw; the next refresh will retry.
        }
    }

    private func scheduleNextBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundRefreshIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 6 * 3600)
        try? BGTaskScheduler.shared.submit(request)
    }
}
