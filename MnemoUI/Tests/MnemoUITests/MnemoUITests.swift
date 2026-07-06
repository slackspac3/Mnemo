import Testing
@testable import MnemoUI

@Suite("MnemoUI")
struct MnemoUITests {
    @Test("DesignSystem colours are accessible")
    func designSystemColours() {
        let _ = DS.Colours.primary
        let _ = DS.Colours.accent
        let _ = DS.Colours.sense
    }
}
