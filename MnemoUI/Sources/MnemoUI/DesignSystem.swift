import SwiftUI

/// Mnemo's shared design system namespace.
public enum DS {
    // MARK: - Colours

    /// Shared color palette for brand, surfaces, text, states, and Mnemo Sense features.
    public enum Colours {
        public static let primary: Color = Color(.sRGB, red: 27.0 / 255.0, green: 58.0 / 255.0, blue: 107.0 / 255.0, opacity: 1.0)
        public static let accent: Color = Color(.sRGB, red: 46.0 / 255.0, green: 117.0 / 255.0, blue: 182.0 / 255.0, opacity: 1.0)
        public static let background: Color = Color(.sRGB, red: 250.0 / 255.0, green: 250.0 / 255.0, blue: 248.0 / 255.0, opacity: 1.0)
        public static let surface: Color = Color(.sRGB, red: 255.0 / 255.0, green: 255.0 / 255.0, blue: 255.0 / 255.0, opacity: 1.0)
        public static let surfaceSecondary: Color = Color(.sRGB, red: 243.0 / 255.0, green: 244.0 / 255.0, blue: 246.0 / 255.0, opacity: 1.0)
        public static let textPrimary: Color = Color(.sRGB, red: 31.0 / 255.0, green: 41.0 / 255.0, blue: 55.0 / 255.0, opacity: 1.0)
        public static let textSecondary: Color = Color(.sRGB, red: 107.0 / 255.0, green: 114.0 / 255.0, blue: 128.0 / 255.0, opacity: 1.0)
        public static let textTertiary: Color = Color(.sRGB, red: 156.0 / 255.0, green: 163.0 / 255.0, blue: 175.0 / 255.0, opacity: 1.0)
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

    /// SF Pro-backed type scale for consistent hierarchy across Mnemo screens.
    public enum Typography {
        public static let largeTitle: Font = .system(size: 34.0, weight: .bold)
        public static let title1: Font = .system(size: 28.0, weight: .bold)
        public static let title2: Font = .system(size: 22.0, weight: .bold)
        public static let title3: Font = .system(size: 18.0, weight: .semibold)
        public static let headline: Font = .system(size: 17.0, weight: .semibold)
        public static let body: Font = .system(size: 17.0, weight: .regular)
        public static let callout: Font = .system(size: 16.0, weight: .regular)
        public static let subheadline: Font = .system(size: 15.0, weight: .regular)
        public static let footnote: Font = .system(size: 13.0, weight: .regular)
        public static let caption1: Font = .system(size: 12.0, weight: .regular)
        public static let caption2: Font = .system(size: 11.0, weight: .regular)
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
            public static let font: Font = .system(size: 12.0, weight: .semibold)
        }

        public enum InputField {
            public static let background: Color = DS.Colours.surfaceSecondary
            public static let cornerRadius: CGFloat = DS.CornerRadius.medium
            public static let height: CGFloat = 48.0
            public static let padding: CGFloat = DS.Spacing.sm
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
