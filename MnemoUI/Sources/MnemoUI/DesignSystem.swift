import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Mnemo's shared design system namespace.
public enum DS {
    // MARK: - Colours

    /// Shared color palette for brand, surfaces, text, states, and Mnemo Sense features.
    public enum Colours {
        public static let brandInk: Color = Color(.sRGB, red: 23.0 / 255.0, green: 35.0 / 255.0, blue: 52.0 / 255.0, opacity: 1.0)
        public static let brandSage: Color = Color(.sRGB, red: 47.0 / 255.0, green: 111.0 / 255.0, blue: 91.0 / 255.0, opacity: 1.0)
        public static let brandSageSoft: Color = brandSage.opacity(0.14)
        public static let brandThread: Color = Color(.sRGB, red: 247.0 / 255.0, green: 250.0 / 255.0, blue: 247.0 / 255.0, opacity: 1.0)
        public static let brandThreadSoft: Color = brandThread.opacity(0.74)

        public static let accent: Color = brandSage
        public static let accentSoft: Color = brandSageSoft
        public static let accentPressed: Color = Color(.sRGB, red: 36.0 / 255.0, green: 87.0 / 255.0, blue: 71.0 / 255.0, opacity: 1.0)
        public static let accentDisabled: Color = brandSage.opacity(0.28)

        #if os(iOS)
        public static let backgroundPrimary: Color = Color(uiColor: .systemBackground)
        public static let backgroundSecondary: Color = Color(uiColor: .secondarySystemBackground)
        public static let backgroundGrouped: Color = Color(uiColor: .systemGroupedBackground)
        public static let backgroundElevated: Color = Color(uiColor: .secondarySystemGroupedBackground)
        public static let surfacePrimary: Color = Color(uiColor: .secondarySystemGroupedBackground)
        public static let surfaceSecondary: Color = Color(uiColor: .tertiarySystemGroupedBackground)
        public static let surfaceElevated: Color = Color(uiColor: .systemBackground)
        public static let surfacePressed: Color = Color(uiColor: .tertiarySystemFill)
        public static let surfaceDisabled: Color = Color(uiColor: .secondarySystemFill)
        public static let success: Color = Color(uiColor: .systemGreen)
        public static let warning: Color = Color(uiColor: .systemOrange)
        public static let destructive: Color = Color(uiColor: .systemRed)
        #else
        public static let backgroundPrimary: Color = Color(nsColor: .windowBackgroundColor)
        public static let backgroundSecondary: Color = Color(nsColor: .underPageBackgroundColor)
        public static let backgroundGrouped: Color = Color(nsColor: .windowBackgroundColor)
        public static let backgroundElevated: Color = Color(nsColor: .controlBackgroundColor)
        public static let surfacePrimary: Color = Color(nsColor: .controlBackgroundColor)
        public static let surfaceSecondary: Color = Color(nsColor: .underPageBackgroundColor)
        public static let surfaceElevated: Color = Color(nsColor: .windowBackgroundColor)
        public static let surfacePressed: Color = Color(nsColor: .selectedContentBackgroundColor).opacity(0.18)
        public static let surfaceDisabled: Color = Color(nsColor: .disabledControlTextColor).opacity(0.14)
        public static let success: Color = .green
        public static let warning: Color = .orange
        public static let destructive: Color = .red
        #endif

        public static let textPrimary: Color = .primary
        public static let textSecondary: Color = .secondary
        public static let textTertiary: Color = .secondary.opacity(0.82)
        public static let textOnAccent: Color = brandThread
        public static let textDestructive: Color = destructive

        public static let borderSubtle: Color = textTertiary.opacity(0.18)
        public static let borderStrong: Color = textTertiary.opacity(0.34)
        public static let borderAccent: Color = accent.opacity(0.28)
        public static let borderDestructive: Color = destructive.opacity(0.34)

        public static let successSoft: Color = success.opacity(0.14)
        public static let warningSoft: Color = warning.opacity(0.14)
        public static let destructiveSoft: Color = destructive.opacity(0.14)

        public static let sourceCardSurface: Color = accentSoft
        public static let sourceCardBorder: Color = borderAccent
        public static let sourceCardAccent: Color = accent
        public static let memoryCardSurface: Color = surfacePrimary
        public static let memoryCardBorder: Color = borderSubtle
        public static let appLockBackground: Color = backgroundGrouped
        public static let appLockSurface: Color = surfaceElevated
        public static let privateBadgeSurface: Color = accentSoft
        public static let privateBadgeText: Color = accent

        public static let sense: Color = Color(.sRGB, red: 65.0 / 255.0, green: 83.0 / 255.0, blue: 72.0 / 255.0, opacity: 1.0)
        public static let senseLight: Color = privateBadgeSurface

        // Legacy aliases kept for existing app surfaces.
        public static let primary: Color = brandInk
        public static let background: Color = backgroundGrouped
        public static let surface: Color = surfacePrimary
        public static let successLight: Color = successSoft
        public static let warningLight: Color = warningSoft
        public static let destructiveLight: Color = destructiveSoft
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
        public static let standard: SwiftUI.Animation = .easeInOut(duration: 0.24)
        public static let slow: SwiftUI.Animation = .easeInOut(duration: 0.38)
        public static let gentleSpring: SwiftUI.Animation = .spring(response: 0.36, dampingFraction: 0.86)
        public static let emphasisSpring: SwiftUI.Animation = .spring(response: 0.42, dampingFraction: 0.78)
        public static let fade: SwiftUI.Animation = .easeInOut(duration: 0.18)
        public static let contentTransition: SwiftUI.Animation = standard
        public static let sheetTransition: SwiftUI.Animation = standard
        public static let spring: SwiftUI.Animation = gentleSpring
        public static let heroAppear: SwiftUI.Animation = .easeOut(duration: 0.34)
        public static let cardAppear: SwiftUI.Animation = gentleSpring
        public static let sourceReveal: SwiftUI.Animation = .easeOut(duration: 0.22)
        public static let memorySaved: SwiftUI.Animation = gentleSpring
        public static let lockAppear: SwiftUI.Animation = .easeOut(duration: 0.26)
        public static let unlockDismiss: SwiftUI.Animation = .easeInOut(duration: 0.18)
        public static let emptyToContent: SwiftUI.Animation = standard
        public static let pressFeedback: SwiftUI.Animation = quick

        public static let scalePress: CGFloat = 0.975

        public static func cardAppearTransition(reduceMotion: Bool) -> AnyTransition {
            reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom))
        }

        public static func sourceRevealTransition(reduceMotion: Bool) -> AnyTransition {
            reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top))
        }

        public static func lockAppearTransition(reduceMotion: Bool) -> AnyTransition {
            reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.985))
        }
    }

    // MARK: - Component Tokens

    /// Reusable component-level tokens composed from the core design system.
    public enum ComponentTokens {
        public enum Card {
            public static let background: Color = DS.Colours.memoryCardSurface
            public static let border: Color = DS.Colours.memoryCardBorder
            public static let cornerRadius: CGFloat = DS.CornerRadius.medium
            public static let shadow: Shadow = DS.Shadows.subtle
            public static let padding: CGFloat = DS.Spacing.md
        }

        public enum PrimaryButton {
            public static let background: Color = DS.Colours.accent
            public static let foreground: Color = DS.Colours.textOnAccent
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
            public static let foreground: Color = DS.Colours.textOnAccent
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
            public static let background: Color = DS.Colours.sourceCardSurface
            public static let border: Color = DS.Colours.sourceCardBorder
            public static let cornerRadius: CGFloat = DS.CornerRadius.medium
            public static let padding: CGFloat = DS.Spacing.md
        }

        public enum EmptyState {
            public static let iconBackground: Color = DS.Colours.accentSoft
            public static let iconForeground: Color = DS.Colours.accent
            public static let maxWidth: CGFloat = 360.0
        }

        public enum LockState {
            public static let iconBackground: Color = DS.Colours.privateBadgeSurface
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
