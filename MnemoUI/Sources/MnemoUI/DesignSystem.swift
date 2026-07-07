import SwiftUI

/// Mnemo's shared design system namespace.
public enum DS {
    // MARK: - Colours

    /// Shared color palette for brand, surfaces, text, states, and Mnemo Sense features.
    public enum Colours {
        public static let primary: Color = Color(.sRGB, red: 27.0 / 255.0, green: 58.0 / 255.0, blue: 107.0 / 255.0, opacity: 1.0)
        public static let accent: Color = Color(.sRGB, red: 46.0 / 255.0, green: 117.0 / 255.0, blue: 182.0 / 255.0, opacity: 1.0)
        #if os(iOS)
        public static let background: Color = Color(uiColor: .systemGroupedBackground)
        public static let surface: Color = Color(uiColor: .secondarySystemGroupedBackground)
        public static let surfaceSecondary: Color = Color(uiColor: .tertiarySystemGroupedBackground)
        #else
        public static let background: Color = Color(nsColor: .windowBackgroundColor)
        public static let surface: Color = Color(nsColor: .controlBackgroundColor)
        public static let surfaceSecondary: Color = Color(nsColor: .underPageBackgroundColor)
        #endif
        public static let textPrimary: Color = .primary
        public static let textSecondary: Color = .secondary
        public static let textTertiary: Color = .secondary.opacity(0.82)
        public static let success: Color = Color(.sRGB, red: 6.0 / 255.0, green: 78.0 / 255.0, blue: 59.0 / 255.0, opacity: 1.0)
        public static let successLight: Color = Color(.sRGB, red: 236.0 / 255.0, green: 253.0 / 255.0, blue: 245.0 / 255.0, opacity: 1.0)
        public static let warning: Color = Color(.sRGB, red: 120.0 / 255.0, green: 53.0 / 255.0, blue: 15.0 / 255.0, opacity: 1.0)
        public static let warningLight: Color = Color(.sRGB, red: 255.0 / 255.0, green: 251.0 / 255.0, blue: 235.0 / 255.0, opacity: 1.0)
        public static let destructive: Color = Color(.sRGB, red: 127.0 / 255.0, green: 29.0 / 255.0, blue: 29.0 / 255.0, opacity: 1.0)
        public static let destructiveLight: Color = Color(.sRGB, red: 254.0 / 255.0, green: 242.0 / 255.0, blue: 242.0 / 255.0, opacity: 1.0)
        public static let sense: Color = Color(.sRGB, red: 76.0 / 255.0, green: 29.0 / 255.0, blue: 149.0 / 255.0, opacity: 1.0)
        public static let senseLight: Color = Color(.sRGB, red: 237.0 / 255.0, green: 233.0 / 255.0, blue: 254.0 / 255.0, opacity: 1.0)
    }

    // MARK: - Typography

    /// SF Pro-backed Dynamic Type scale for consistent hierarchy across Mnemo screens.
    public enum Typography {
        public static let largeTitle: Font = .largeTitle.weight(.bold)
        public static let title1: Font = .title.weight(.bold)
        public static let title2: Font = .title2.weight(.bold)
        public static let title3: Font = .title3.weight(.semibold)
        public static let headline: Font = .headline
        public static let body: Font = .body
        public static let callout: Font = .callout
        public static let subheadline: Font = .subheadline
        public static let footnote: Font = .footnote
        public static let caption1: Font = .caption
        public static let caption2: Font = .caption2
    }

    // MARK: - Spacing

    /// Eight-point spacing grid used for layout rhythm and padding.
    public enum Spacing {
        public static let xs: CGFloat = 4.0
        public static let sm: CGFloat = 8.0
        public static let md: CGFloat = 16.0
        public static let lg: CGFloat = 24.0
        public static let xl: CGFloat = 32.0
        public static let xxl: CGFloat = 48.0
        public static let xxxl: CGFloat = 64.0
    }

    // MARK: - Corner Radius

    /// Corner radius tokens for cards, controls, pills, and avatars.
    public enum CornerRadius {
        public static let small: CGFloat = 8.0
        public static let medium: CGFloat = 12.0
        public static let large: CGFloat = 16.0
        public static let xlarge: CGFloat = 24.0
        public static let full: CGFloat = 999.0
    }

    // MARK: - Shadows

    /// Elevation tokens expressed as reusable shadow structs.
    public enum Shadows {
        public static let subtle: Shadow = Shadow(opacity: 0.06, radius: 4.0, y: 2.0)
        public static let medium: Shadow = Shadow(opacity: 0.10, radius: 8.0, y: 4.0)
        public static let strong: Shadow = Shadow(opacity: 0.15, radius: 16.0, y: 8.0)
    }

    // MARK: - Animation

    /// Motion timings for feedback, transitions, and spring interactions.
    public enum Animation {
        public static let quick: SwiftUI.Animation = .easeInOut(duration: 0.15)
        public static let standard: SwiftUI.Animation = .easeInOut(duration: 0.25)
        public static let slow: SwiftUI.Animation = .easeInOut(duration: 0.4)
        public static let spring: SwiftUI.Animation = .spring(response: 0.4, dampingFraction: 0.75)
    }

    // MARK: - Component Tokens

    /// Reusable component-level tokens composed from the core design system.
    public enum ComponentTokens {
        public enum Card {
            public static let background: Color = DS.Colours.surface
            public static let cornerRadius: CGFloat = DS.CornerRadius.medium
            public static let shadow: Shadow = DS.Shadows.subtle
            public static let padding: CGFloat = DS.Spacing.md
        }

        public enum PrimaryButton {
            public static let background: Color = DS.Colours.accent
            public static let foreground: Color = .white
            public static let cornerRadius: CGFloat = DS.CornerRadius.medium
            public static let height: CGFloat = 52.0
        }

        public enum SecondaryButton {
            public static let background: Color = DS.Colours.surfaceSecondary
            public static let foreground: Color = DS.Colours.textPrimary
            public static let cornerRadius: CGFloat = DS.CornerRadius.medium
            public static let height: CGFloat = 52.0
        }

        public enum DestructiveButton {
            public static let background: Color = DS.Colours.destructive
            public static let foreground: Color = .white
            public static let cornerRadius: CGFloat = DS.CornerRadius.medium
            public static let height: CGFloat = 52.0
        }

        public enum SenseBadge {
            public static let background: Color = DS.Colours.senseLight
            public static let foreground: Color = DS.Colours.sense
            public static let cornerRadius: CGFloat = DS.CornerRadius.full
            public static let font: Font = DS.Typography.caption1.weight(.semibold)
        }

        public enum InputField {
            public static let background: Color = DS.Colours.surfaceSecondary
            public static let cornerRadius: CGFloat = DS.CornerRadius.medium
            public static let height: CGFloat = 48.0
            public static let padding: CGFloat = DS.Spacing.sm
        }

        public enum SourceCard {
            public static let background: Color = DS.Colours.surface
            public static let border: Color = DS.Colours.accent.opacity(0.16)
            public static let cornerRadius: CGFloat = DS.CornerRadius.medium
            public static let padding: CGFloat = DS.Spacing.md
        }

        public enum EmptyState {
            public static let iconBackground: Color = DS.Colours.accent.opacity(0.10)
            public static let iconForeground: Color = DS.Colours.accent
            public static let maxWidth: CGFloat = 360.0
        }

        public enum LockState {
            public static let iconBackground: Color = DS.Colours.accent.opacity(0.12)
            public static let iconForeground: Color = DS.Colours.accent
            public static let cardPadding: CGFloat = DS.Spacing.lg
        }
    }

    /// Reusable shadow definition for applying Mnemo elevation tokens.
    public struct Shadow {
        public let opacity: CGFloat
        public let radius: CGFloat
        public let x: CGFloat
        public let y: CGFloat

        public var color: Color {
            Color.black.opacity(Double(opacity))
        }

        public init(opacity: CGFloat, radius: CGFloat, x: CGFloat = 0.0, y: CGFloat) {
            self.opacity = opacity
            self.radius = radius
            self.x = x
            self.y = y
        }
    }
}

public extension Font {
    /// Mnemo typography aliases backed by DS.Typography.
    static var mnemoLargeTitle: Font { DS.Typography.largeTitle }
    static var mnemoTitle1: Font { DS.Typography.title1 }
    static var mnemoTitle2: Font { DS.Typography.title2 }
    static var mnemoTitle3: Font { DS.Typography.title3 }
    static var mnemoHeadline: Font { DS.Typography.headline }
    static var mnemoBody: Font { DS.Typography.body }
    static var mnemoCallout: Font { DS.Typography.callout }
    static var mnemoSubheadline: Font { DS.Typography.subheadline }
    static var mnemoFootnote: Font { DS.Typography.footnote }
    static var mnemoCaption1: Font { DS.Typography.caption1 }
    static var mnemoCaption2: Font { DS.Typography.caption2 }
}
