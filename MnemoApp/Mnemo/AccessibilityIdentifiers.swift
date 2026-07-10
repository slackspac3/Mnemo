enum AccessibilityID {
    enum Onboarding {
        static let continueButton = "onboarding.continue"
        static let completeButton = "onboarding.complete"
    }

    enum Main {
        static let tabView = "main.tabView"
        static let chatTab = "tab.chat"
        static let browseTab = "tab.browse"
        static let capture = "tab.capture"
        static let settings = "tab.settings"
    }

    enum CaptureText {
        static let open = "capture.text.open"
        static let input = "capture.text.input"
        static let extract = "capture.text.extract"
        static let review = "capture.text.review"
        static let save = "capture.text.save"
        static let dismiss = "capture.text.dismiss"
    }

    enum Browse {
        static let screen = "browse.screen"
        static let memoryCell = "browse.memoryCell"
    }

    enum Chat {
        static let landing = "chat.landing"
        static let input = "chat.input"
        static let send = "chat.send"
        static let messageUser = "chat.message.user"
        static let messageAssistant = "chat.message.assistant"
        static let sourceCard = "chat.sourceCard"
        static let sourceCardPrimary = "chat.sourceCard.primary"
        static let sourceType = "chat.sourceCard.sourceType"
        static let newConversation = "chat.newConversation"
        static let captureMenu = "chat.captureMenu"
        static let sourceDisclosure = "chat.sourceDisclosure"
    }

    enum MemoryDetail {
        static let title = "memoryDetail.title"
        static let archive = "memoryDetail.archive"
        static let delete = "memoryDetail.delete"
    }

    enum Settings {
        static let securitySection = "settings.securitySection"
        static let appLockToggle = "settings.appLockToggle"
        static let deleteAllData = "settings.deleteAllData"
    }

    enum AppLock {
        static let screen = "appLock.screen"
        static let unlockButton = "appLock.unlockButton"
        static let errorMessage = "appLock.errorMessage"
    }
}
