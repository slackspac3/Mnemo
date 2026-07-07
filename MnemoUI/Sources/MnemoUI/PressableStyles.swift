import SwiftUI

/// Subtle press feedback for custom Mnemo controls. Uses opacity only when Reduce Motion is enabled.
public struct MnemoPressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1.0 : (configuration.isPressed ? DS.Animation.scalePress : 1.0))
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(reduceMotion ? DS.Animation.fade : DS.Animation.quick, value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == MnemoPressableButtonStyle {
    static var mnemoPressable: MnemoPressableButtonStyle {
        MnemoPressableButtonStyle()
    }
}
