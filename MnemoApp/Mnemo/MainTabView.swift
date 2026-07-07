import SwiftUI
import MnemoUI

/// Root tab container shown after onboarding.
struct MainTabView: View {

    @State private var coordinator = NavigationCoordinator.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        @Bindable var coordinator = coordinator

        TabView(selection: $coordinator.activeTab) {
            ChatView()
                .accessibilityIdentifier(AccessibilityID.Main.chatTab)
                .tabItem {
                    Label(NavigationCoordinator.Tab.chat.rawValue, systemImage: NavigationCoordinator.Tab.chat.icon)
                }
                .tag(NavigationCoordinator.Tab.chat)

            BrowseView()
                .accessibilityIdentifier(AccessibilityID.Main.browseTab)
                .tabItem {
                    Label(NavigationCoordinator.Tab.browse.rawValue, systemImage: NavigationCoordinator.Tab.browse.icon)
                }
                .tag(NavigationCoordinator.Tab.browse)
        }
        .accessibilityIdentifier(AccessibilityID.Main.tabView)
        .tint(DS.Colours.accent)
        .environment(coordinator)
        .sheet(item: $coordinator.activeSheet) { sheet in
            switch sheet {
            case .captureText:
                CaptureTextSheet()
            case .captureVoice:
                CaptureVoiceSheet()
            case .captureImage(let source):
                CaptureImageSheet(source: source)
            case .settings:
                SettingsView()
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if coordinator.activeTab != .chat {
                CaptureButton()
                    .environment(coordinator)
                    .padding(.trailing, DS.Spacing.md)
                    .padding(.bottom, DS.Spacing.xxxl + DS.Spacing.lg)
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? DS.Animation.fade : DS.Animation.standard, value: coordinator.activeTab)
    }
}
