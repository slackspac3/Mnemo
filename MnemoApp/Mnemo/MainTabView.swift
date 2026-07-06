import SwiftUI
import MnemoUI

/// Root tab container shown after onboarding.
struct MainTabView: View {

    @State private var coordinator = NavigationCoordinator.shared

    var body: some View {
        @Bindable var coordinator = coordinator

        TabView(selection: $coordinator.activeTab) {
            ChatView()
                .tabItem {
                    Label(NavigationCoordinator.Tab.chat.rawValue, systemImage: NavigationCoordinator.Tab.chat.icon)
                }
                .tag(NavigationCoordinator.Tab.chat)

            BrowseView()
                .tabItem {
                    Label(NavigationCoordinator.Tab.browse.rawValue, systemImage: NavigationCoordinator.Tab.browse.icon)
                }
                .tag(NavigationCoordinator.Tab.browse)

            ThreadsView()
                .tabItem {
                    Label(NavigationCoordinator.Tab.threads.rawValue, systemImage: NavigationCoordinator.Tab.threads.icon)
                }
                .tag(NavigationCoordinator.Tab.threads)
        }
        .tint(DS.Colours.accent)
        .environment(coordinator)
        .sheet(item: $coordinator.activeSheet) { sheet in
            switch sheet {
            case .captureText:
                CaptureTextSheet()
            case .captureVoice:
                CaptureVoiceSheet()
            case .captureImage:
                CaptureImageSheet()
            case .settings:
                SettingsView()
            case .memoryDetail(let id):
                MemoryDetailPlaceholderView(memoryId: id)
            case .threadProposal(let id):
                ThreadProposalPlaceholderView(threadId: id)
            }
        }
        .overlay(alignment: .bottom) {
            if coordinator.activeTab != .chat {
                CaptureButton()
                    .environment(coordinator)
                    .padding(.bottom, DS.Spacing.xxxl + DS.Spacing.xxxl + DS.Spacing.md)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(DS.Animation.standard, value: coordinator.activeTab)
    }
}

struct MemoryDetailPlaceholderView: View {
    let memoryId: UUID

    var body: some View {
        ZStack {
            DS.Colours.background.ignoresSafeArea()
            VStack(spacing: DS.Spacing.sm) {
                Text("Memory Detail")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colours.textPrimary)
                Text("Phase 9")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textSecondary)
                Text(memoryId.uuidString)
                    .font(DS.Typography.caption2)
                    .foregroundStyle(DS.Colours.textTertiary)
            }
            .padding(DS.Spacing.md)
        }
    }
}

struct ThreadProposalPlaceholderView: View {
    let threadId: UUID

    var body: some View {
        ZStack {
            DS.Colours.background.ignoresSafeArea()
            VStack(spacing: DS.Spacing.sm) {
                Text("Thread Proposal")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colours.textPrimary)
                Text("Phase 9")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textSecondary)
                Text(threadId.uuidString)
                    .font(DS.Typography.caption2)
                    .foregroundStyle(DS.Colours.textTertiary)
            }
            .padding(DS.Spacing.md)
        }
    }
}
