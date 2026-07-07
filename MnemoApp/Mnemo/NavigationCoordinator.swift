import SwiftUI
import MnemoCore

/// Central navigation state for the entire app.
/// All sheets, tabs, and navigation paths go through here.
@Observable
final class NavigationCoordinator {

    static let shared = NavigationCoordinator()

    var activeTab: Tab = .chat
    var path = NavigationPath()
    var activeSheet: Sheet?

    enum Tab: String, CaseIterable {
        case chat = "Chat"
        case browse = "Browse"
        case capture = "Capture"

        var icon: String {
            switch self {
            case .chat: return "bubble.left.and.bubble.right"
            case .browse: return "square.grid.2x2"
            case .capture: return "plus.circle.fill"
            }
        }
    }

    enum Sheet: Identifiable {
        case captureText
        case captureVoice
        case captureImage(ImageCaptureSource)
        case settings

        var id: String {
            switch self {
            case .captureText:
                return "captureText"
            case .captureVoice:
                return "captureVoice"
            case .captureImage(let source):
                return "captureImage-\(source.rawValue)"
            case .settings:
                return "settings"
            }
        }
    }

    func present(_ sheet: Sheet) {
        activeSheet = sheet
    }

    func dismiss() {
        activeSheet = nil
    }
}

enum ImageCaptureSource: String {
    case camera
    case photoLibrary
}
