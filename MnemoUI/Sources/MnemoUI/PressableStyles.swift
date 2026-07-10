import SwiftUI

/// Subtle press feedback for custom Mnemo controls. Uses opacity only when Reduce Motion is enabled.
public struct MnemoPressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1.0 : (configuration.isPressed ? DS.Animation.scalePress : 1.0))
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(reduceMotion ? DS.Animation.fade : DS.Animation.pressFeedback, value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == MnemoPressableButtonStyle {
    static var mnemoPressable: MnemoPressableButtonStyle {
        MnemoPressableButtonStyle()
    }
}

/// Shared rendering policy for opaque content, native material fallbacks, and iOS 26 glass controls.
public struct MnemoSurfaceModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let role: DS.Materials.Role
    private let cornerRadius: CGFloat

    public init(role: DS.Materials.Role, cornerRadius: CGFloat) {
        self.role = role
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        rendered(content: content, shape: shape)
            .overlay {
                shape.stroke(
                    colorSchemeContrast == .increased ? DS.Colours.borderStrong : borderColor,
                    lineWidth: colorSchemeContrast == .increased ? 1.5 : 1.0
                )
            }
    }

    @ViewBuilder
    private func rendered(
        content: Content,
        shape: RoundedRectangle
    ) -> some View {
        if role == .contentFallback || reduceTransparency {
            content.background(DS.Materials.opaqueFallback(for: role), in: shape)
        } else if role == .floatingControl {
            if #available(iOS 26.0, macOS 26.0, *) {
                content.glassEffect(.regular.tint(DS.Colours.glassTint).interactive(), in: shape)
            } else {
                content.background(.regularMaterial, in: shape)
            }
        } else {
            content.background(.thinMaterial, in: shape)
        }
    }

    private var borderColor: Color {
        switch role {
        case .floatingControl:
            return DS.Colours.glassBorder
        case .contentFallback, .navigationChrome, .compactControl, .sheetChrome:
            return DS.Colours.separator
        }
    }
}

public extension View {
    /// Applies Mnemo's accessibility-aware surface treatment for the requested semantic role.
    func mnemoSurface(
        _ role: DS.Materials.Role,
        cornerRadius: CGFloat = DS.CornerRadius.medium
    ) -> some View {
        modifier(MnemoSurfaceModifier(role: role, cornerRadius: cornerRadius))
    }
}

/// Filled accent action with a stable 44-point minimum hit target and restrained press feedback.
public struct MnemoPrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DS.Typography.headline)
            .foregroundStyle(isEnabled ? DS.Colours.textOnAccent : DS.Colours.textSecondary)
            .frame(maxWidth: .infinity, minHeight: DS.ComponentTokens.PrimaryButton.height)
            .padding(.horizontal, DS.Spacing.md)
            .background(
                isEnabled
                    ? (configuration.isPressed ? DS.Colours.controlAccentPressed : DS.Colours.controlAccent)
                    : DS.Colours.surfaceDisabled,
                in: RoundedRectangle(cornerRadius: DS.CornerRadius.medium, style: .continuous)
            )
            .scaleEffect(reduceMotion ? 1.0 : (configuration.isPressed ? DS.Animation.scalePress : 1.0))
            .opacity(configuration.isPressed ? 0.94 : 1.0)
            .animation(reduceMotion ? DS.Animation.fade : DS.Animation.pressFeedback, value: configuration.isPressed)
    }
}

/// Opaque secondary action for text-heavy layouts and Reduce Transparency-safe controls.
public struct MnemoSecondaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DS.Typography.headline)
            .foregroundStyle(isEnabled ? DS.Colours.textPrimary : DS.Colours.textTertiary)
            .frame(maxWidth: .infinity, minHeight: DS.ComponentTokens.SecondaryButton.height)
            .padding(.horizontal, DS.Spacing.md)
            .background(
                configuration.isPressed ? DS.Colours.surfacePressed : DS.Colours.controlFallback,
                in: RoundedRectangle(cornerRadius: DS.CornerRadius.medium, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: DS.CornerRadius.medium, style: .continuous)
                    .stroke(
                        colorSchemeContrast == .increased ? DS.Colours.borderStrong : DS.Colours.separator,
                        lineWidth: colorSchemeContrast == .increased ? 1.5 : 1.0
                    )
            }
            .scaleEffect(reduceMotion ? 1.0 : (configuration.isPressed ? DS.Animation.scalePress : 1.0))
            .opacity(isEnabled ? 1.0 : 0.72)
            .animation(reduceMotion ? DS.Animation.fade : DS.Animation.pressFeedback, value: configuration.isPressed)
    }
}

/// Compact custom control treatment. It is the only shared component that opts into custom Liquid Glass.
public struct MnemoFloatingControlButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(DS.Colours.accent)
            .frame(minWidth: 44.0, minHeight: 44.0)
            .padding(.horizontal, DS.Spacing.sm)
            .mnemoSurface(.floatingControl, cornerRadius: DS.CornerRadius.full)
            .scaleEffect(reduceMotion ? 1.0 : (configuration.isPressed ? DS.Animation.scalePress : 1.0))
            .opacity(configuration.isPressed ? 0.90 : 1.0)
            .animation(reduceMotion ? DS.Animation.fade : DS.Animation.pressFeedback, value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == MnemoPrimaryButtonStyle {
    static var mnemoPrimary: MnemoPrimaryButtonStyle { MnemoPrimaryButtonStyle() }
}

public extension ButtonStyle where Self == MnemoSecondaryButtonStyle {
    static var mnemoSecondary: MnemoSecondaryButtonStyle { MnemoSecondaryButtonStyle() }
}

public extension ButtonStyle where Self == MnemoFloatingControlButtonStyle {
    static var mnemoFloatingControl: MnemoFloatingControlButtonStyle { MnemoFloatingControlButtonStyle() }
}

public struct MnemoCardModifier: ViewModifier {
    private let padding: CGFloat

    public init(padding: CGFloat) {
        self.padding = padding
    }

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .mnemoSurface(.contentFallback, cornerRadius: DS.ComponentTokens.Card.cornerRadius)
    }
}

public struct MnemoSourceCardModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    public init() {}

    public func body(content: Content) -> some View {
        content
            .padding(DS.ComponentTokens.SourceCard.padding)
            .background(
                DS.Colours.sourceSurface,
                in: RoundedRectangle(
                    cornerRadius: DS.ComponentTokens.SourceCard.cornerRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: DS.ComponentTokens.SourceCard.cornerRadius,
                    style: .continuous
                )
                .stroke(
                    colorSchemeContrast == .increased
                        ? DS.Colours.sourceAccent
                        : DS.Colours.sourceBorder,
                    lineWidth: colorSchemeContrast == .increased ? 1.5 : 1.0
                )
            }
    }
}

public struct MnemoInputSurfaceModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    private let isFocused: Bool

    public init(isFocused: Bool = false) {
        self.isFocused = isFocused
    }

    public func body(content: Content) -> some View {
        content
            .padding(DS.ComponentTokens.InputField.padding)
            .background(
                DS.Colours.controlFallback,
                in: RoundedRectangle(
                    cornerRadius: DS.ComponentTokens.InputField.cornerRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: DS.ComponentTokens.InputField.cornerRadius,
                    style: .continuous
                )
                .stroke(
                    isFocused
                        ? DS.Colours.focus
                        : (colorSchemeContrast == .increased ? DS.Colours.borderStrong : DS.Colours.separator),
                    lineWidth: isFocused || colorSchemeContrast == .increased ? 1.5 : 1.0
                )
            }
    }
}

public extension View {
    func mnemoCard(padding: CGFloat = DS.ComponentTokens.Card.padding) -> some View {
        modifier(MnemoCardModifier(padding: padding))
    }

    func mnemoSourceCard() -> some View {
        modifier(MnemoSourceCardModifier())
    }

    func mnemoInputSurface(isFocused: Bool = false) -> some View {
        modifier(MnemoInputSurfaceModifier(isFocused: isFocused))
    }
}
