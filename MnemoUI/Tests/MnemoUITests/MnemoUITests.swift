import Testing
@testable import MnemoUI

@Suite("MnemoUI")
struct MnemoUITests {
    @Test("DesignSystem colours are accessible")
    func designSystemColours() {
        let _ = DS.Colours.brandInk
        let _ = DS.Colours.brandSage
        let _ = DS.Colours.brandSageSoft
        let _ = DS.Colours.brandThread
        let _ = DS.Colours.brandThreadSoft
        let _ = DS.Colours.primary
        let _ = DS.Colours.accent
        let _ = DS.Colours.accentSoft
        let _ = DS.Colours.accentPressed
        let _ = DS.Colours.accentDisabled
        let _ = DS.Colours.backgroundPrimary
        let _ = DS.Colours.backgroundSecondary
        let _ = DS.Colours.backgroundGrouped
        let _ = DS.Colours.backgroundElevated
        let _ = DS.Colours.surfacePrimary
        let _ = DS.Colours.surfaceSecondary
        let _ = DS.Colours.surfaceElevated
        let _ = DS.Colours.surfacePressed
        let _ = DS.Colours.surfaceDisabled
        let _ = DS.Colours.textOnAccent
        let _ = DS.Colours.textDestructive
        let _ = DS.Colours.borderSubtle
        let _ = DS.Colours.borderStrong
        let _ = DS.Colours.borderAccent
        let _ = DS.Colours.borderDestructive
        let _ = DS.Colours.successSoft
        let _ = DS.Colours.warningSoft
        let _ = DS.Colours.destructiveSoft
        let _ = DS.Colours.sourceCardSurface
        let _ = DS.Colours.sourceCardBorder
        let _ = DS.Colours.sourceCardAccent
        let _ = DS.Colours.memoryCardSurface
        let _ = DS.Colours.memoryCardBorder
        let _ = DS.Colours.appLockBackground
        let _ = DS.Colours.appLockSurface
        let _ = DS.Colours.privateBadgeSurface
        let _ = DS.Colours.privateBadgeText
        let _ = DS.Colours.sense
    }

    @Test("Logo mark is available to app surfaces")
    func logoMark() {
        let _ = MnemoLogoMark(size: 48.0, style: .subtle)
    }
}
