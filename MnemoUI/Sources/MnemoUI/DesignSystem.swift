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
        #if os(iOS)
        private static func adaptive(
            light: UIColor,
            dark: UIColor,
            highContrastLight: UIColor? = nil,
            highContrastDark: UIColor? = nil
        ) -> Color {
            Color(uiColor: UIColor { trait in
                switch (trait.userInterfaceStyle, trait.accessibilityContrast) {
                case (.dark, .high):
                    return highContrastDark ?? dark
                case (_, .high):
                    return highContrastLight ?? light
                case (.dark, _):
                    return dark
                default:
                    return light
                }
            })
        }
        #endif

        // MARK: Brand - fixed values, same in both modes
        public static let brandInk: Color = Color(.sRGB, red: 35.0 / 255.0, green: 40.0 / 255.0, blue: 32.0 / 255.0, opacity: 1.0)
        public static let brandIndigo: Color = Color(.sRGB, red: 68.0 / 255.0, green: 56.0 / 255.0, blue: 168.0 / 255.0, opacity: 1.0)
        public static let brandIndigoLight: Color = Color(.sRGB, red: 154.0 / 255.0, green: 150.0 / 255.0, blue: 255.0 / 255.0, opacity: 1.0)
        public static let brandParchment: Color = Color(.sRGB, red: 245.0 / 255.0, green: 247.0 / 255.0, blue: 241.0 / 255.0, opacity: 1.0)
        public static let brandOlive: Color = Color(.sRGB, red: 92.0 / 255.0, green: 104.0 / 255.0, blue: 56.0 / 255.0, opacity: 1.0)
        public static let brandViolet: Color = Color(.sRGB, red: 109.0 / 255.0, green: 40.0 / 255.0, blue: 217.0 / 255.0, opacity: 1.0)
        public static let brandVioletLight: Color = Color(.sRGB, red: 167.0 / 255.0, green: 139.0 / 255.0, blue: 250.0 / 255.0, opacity: 1.0)

        #if os(iOS)
        // MARK: Backgrounds
        public static let backgroundPrimary: Color = adaptive(
            light: UIColor(red: 245.0 / 255.0, green: 247.0 / 255.0, blue: 241.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 19.0 / 255.0, green: 23.0 / 255.0, blue: 17.0 / 255.0, alpha: 1.0)
        )
        public static let backgroundSecondary: Color = adaptive(
            light: UIColor(red: 236.0 / 255.0, green: 239.0 / 255.0, blue: 230.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 25.0 / 255.0, green: 30.0 / 255.0, blue: 21.0 / 255.0, alpha: 1.0)
        )
        public static let backgroundGrouped: Color = adaptive(
            light: UIColor(red: 245.0 / 255.0, green: 247.0 / 255.0, blue: 241.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 19.0 / 255.0, green: 23.0 / 255.0, blue: 17.0 / 255.0, alpha: 1.0)
        )
        public static let backgroundElevated: Color = adaptive(
            light: UIColor(red: 255.0 / 255.0, green: 255.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 36.0 / 255.0, green: 44.0 / 255.0, blue: 32.0 / 255.0, alpha: 1.0)
        )

        // MARK: Surfaces - stable content planes over the canvas
        public static let surfacePrimary: Color = adaptive(
            light: UIColor(red: 252.0 / 255.0, green: 253.0 / 255.0, blue: 249.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 29.0 / 255.0, green: 35.0 / 255.0, blue: 26.0 / 255.0, alpha: 1.0)
        )
        public static let surfaceSecondary: Color = adaptive(
            light: UIColor(red: 231.0 / 255.0, green: 236.0 / 255.0, blue: 221.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 42.0 / 255.0, green: 49.0 / 255.0, blue: 34.0 / 255.0, alpha: 1.0)
        )
        public static let surfaceElevated: Color = adaptive(
            light: UIColor(red: 255.0 / 255.0, green: 255.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 36.0 / 255.0, green: 44.0 / 255.0, blue: 32.0 / 255.0, alpha: 1.0)
        )
        public static let surfacePressed: Color = adaptive(
            light: UIColor(red: 221.0 / 255.0, green: 227.0 / 255.0, blue: 207.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 51.0 / 255.0, green: 59.0 / 255.0, blue: 40.0 / 255.0, alpha: 1.0)
        )
        public static let surfaceDisabled: Color = adaptive(
            light: UIColor(red: 213.0 / 255.0, green: 208.0 / 255.0, blue: 200.0 / 255.0, alpha: 0.5),
            dark: UIColor(red: 40.0 / 255.0, green: 52.0 / 255.0, blue: 31.0 / 255.0, alpha: 0.5)
        )

        // MARK: Text
        public static let textPrimary: Color = adaptive(
            light: UIColor(red: 35.0 / 255.0, green: 40.0 / 255.0, blue: 32.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 242.0 / 255.0, green: 245.0 / 255.0, blue: 237.0 / 255.0, alpha: 1.0),
            highContrastLight: .black,
            highContrastDark: .white
        )
        public static let textSecondary: Color = adaptive(
            light: UIColor(red: 102.0 / 255.0, green: 112.0 / 255.0, blue: 100.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 187.0 / 255.0, green: 195.0 / 255.0, blue: 179.0 / 255.0, alpha: 1.0),
            highContrastLight: UIColor(red: 74.0 / 255.0, green: 82.0 / 255.0, blue: 72.0 / 255.0, alpha: 1.0),
            highContrastDark: UIColor(red: 216.0 / 255.0, green: 222.0 / 255.0, blue: 207.0 / 255.0, alpha: 1.0)
        )
        public static let textTertiary: Color = adaptive(
            light: UIColor(red: 108.0 / 255.0, green: 116.0 / 255.0, blue: 100.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 142.0 / 255.0, green: 150.0 / 255.0, blue: 132.0 / 255.0, alpha: 1.0),
            highContrastLight: UIColor(red: 79.0 / 255.0, green: 87.0 / 255.0, blue: 73.0 / 255.0, alpha: 1.0),
            highContrastDark: UIColor(red: 191.0 / 255.0, green: 199.0 / 255.0, blue: 182.0 / 255.0, alpha: 1.0)
        )
        public static let textOnAccent: Color = adaptive(
            light: .white,
            dark: UIColor(red: 242.0 / 255.0, green: 245.0 / 255.0, blue: 237.0 / 255.0, alpha: 1.0)
        )
        public static let textOnDestructive: Color = adaptive(
            light: .white,
            dark: UIColor(red: 35.0 / 255.0, green: 40.0 / 255.0, blue: 32.0 / 255.0, alpha: 1.0)
        )

        // MARK: Accent - olive, adaptive brightness
        public static let accent: Color = adaptive(
            light: UIColor(red: 92.0 / 255.0, green: 104.0 / 255.0, blue: 56.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 184.0 / 255.0, green: 201.0 / 255.0, blue: 138.0 / 255.0, alpha: 1.0)
        )
        public static let accentSoft: Color = adaptive(
            light: UIColor(red: 228.0 / 255.0, green: 234.0 / 255.0, blue: 214.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 48.0 / 255.0, green: 57.0 / 255.0, blue: 35.0 / 255.0, alpha: 1.0)
        )
        public static let accentPressed: Color = adaptive(
            light: UIColor(red: 74.0 / 255.0, green: 84.0 / 255.0, blue: 48.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 158.0 / 255.0, green: 176.0 / 255.0, blue: 114.0 / 255.0, alpha: 1.0)
        )
        public static let accentDisabled: Color = adaptive(
            light: UIColor(red: 92.0 / 255.0, green: 104.0 / 255.0, blue: 56.0 / 255.0, alpha: 0.28),
            dark: UIColor(red: 184.0 / 255.0, green: 201.0 / 255.0, blue: 138.0 / 255.0, alpha: 0.30)
        )

        // MARK: Borders - visible structure, editorial feel
        public static let borderSubtle: Color = adaptive(
            light: UIColor(red: 35.0 / 255.0, green: 40.0 / 255.0, blue: 32.0 / 255.0, alpha: 0.10),
            dark: UIColor(red: 242.0 / 255.0, green: 245.0 / 255.0, blue: 237.0 / 255.0, alpha: 0.10),
            highContrastLight: UIColor(red: 35.0 / 255.0, green: 40.0 / 255.0, blue: 32.0 / 255.0, alpha: 0.28),
            highContrastDark: UIColor(red: 242.0 / 255.0, green: 245.0 / 255.0, blue: 237.0 / 255.0, alpha: 0.30)
        )
        public static let borderStrong: Color = adaptive(
            light: UIColor(red: 35.0 / 255.0, green: 40.0 / 255.0, blue: 32.0 / 255.0, alpha: 0.22),
            dark: UIColor(red: 242.0 / 255.0, green: 245.0 / 255.0, blue: 237.0 / 255.0, alpha: 0.24),
            highContrastLight: UIColor(red: 35.0 / 255.0, green: 40.0 / 255.0, blue: 32.0 / 255.0, alpha: 0.48),
            highContrastDark: UIColor(red: 242.0 / 255.0, green: 245.0 / 255.0, blue: 237.0 / 255.0, alpha: 0.50)
        )
        public static let borderAccent: Color = adaptive(
            light: UIColor(red: 92.0 / 255.0, green: 104.0 / 255.0, blue: 56.0 / 255.0, alpha: 0.24),
            dark: UIColor(red: 184.0 / 255.0, green: 201.0 / 255.0, blue: 138.0 / 255.0, alpha: 0.28)
        )
        public static let borderDestructive: Color = adaptive(
            light: UIColor(red: 220.0 / 255.0, green: 38.0 / 255.0, blue: 38.0 / 255.0, alpha: 0.30),
            dark: UIColor(red: 248.0 / 255.0, green: 113.0 / 255.0, blue: 113.0 / 255.0, alpha: 0.30)
        )

        // MARK: Semantic states
        public static let success: Color = adaptive(
            light: UIColor(red: 63.0 / 255.0, green: 122.0 / 255.0, blue: 78.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 127.0 / 255.0, green: 199.0 / 255.0, blue: 154.0 / 255.0, alpha: 1.0)
        )
        public static let warning: Color = adaptive(
            light: UIColor(red: 180.0 / 255.0, green: 83.0 / 255.0, blue: 9.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 251.0 / 255.0, green: 191.0 / 255.0, blue: 36.0 / 255.0, alpha: 1.0)
        )
        public static let destructive: Color = adaptive(
            light: UIColor(red: 185.0 / 255.0, green: 28.0 / 255.0, blue: 28.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 248.0 / 255.0, green: 113.0 / 255.0, blue: 113.0 / 255.0, alpha: 1.0)
        )
        public static let successSoft: Color = adaptive(
            light: UIColor(red: 63.0 / 255.0, green: 122.0 / 255.0, blue: 78.0 / 255.0, alpha: 0.10),
            dark: UIColor(red: 127.0 / 255.0, green: 199.0 / 255.0, blue: 154.0 / 255.0, alpha: 0.15)
        )
        public static let warningSoft: Color = adaptive(
            light: UIColor(red: 180.0 / 255.0, green: 83.0 / 255.0, blue: 9.0 / 255.0, alpha: 0.10),
            dark: UIColor(red: 251.0 / 255.0, green: 191.0 / 255.0, blue: 36.0 / 255.0, alpha: 0.12)
        )
        public static let destructiveSoft: Color = adaptive(
            light: UIColor(red: 185.0 / 255.0, green: 28.0 / 255.0, blue: 28.0 / 255.0, alpha: 0.10),
            dark: UIColor(red: 248.0 / 255.0, green: 113.0 / 255.0, blue: 113.0 / 255.0, alpha: 0.12)
        )

        // MARK: Mnemo Sense - violet, premium tier
        public static let sense: Color = adaptive(
            light: UIColor(red: 109.0 / 255.0, green: 40.0 / 255.0, blue: 217.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 167.0 / 255.0, green: 139.0 / 255.0, blue: 250.0 / 255.0, alpha: 1.0)
        )
        public static let senseLight: Color = adaptive(
            light: UIColor(red: 109.0 / 255.0, green: 40.0 / 255.0, blue: 217.0 / 255.0, alpha: 0.10),
            dark: UIColor(red: 167.0 / 255.0, green: 139.0 / 255.0, blue: 250.0 / 255.0, alpha: 0.15)
        )

        // MARK: Semantic roles
        public static let canvas: Color = backgroundPrimary
        public static let canvasSecondary: Color = backgroundSecondary
        public static let contentSurface: Color = surfacePrimary
        public static let contentSurfaceElevated: Color = surfaceElevated
        public static let controlFallback: Color = surfaceElevated
        public static let glassTint: Color = accent.opacity(0.12)
        public static let glassBorder: Color = borderAccent
        public static let controlAccent: Color = adaptive(
            light: UIColor(red: 92.0 / 255.0, green: 104.0 / 255.0, blue: 56.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 93.0 / 255.0, green: 105.0 / 255.0, blue: 59.0 / 255.0, alpha: 1.0)
        )
        public static let controlAccentPressed: Color = adaptive(
            light: UIColor(red: 74.0 / 255.0, green: 84.0 / 255.0, blue: 48.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 76.0 / 255.0, green: 86.0 / 255.0, blue: 47.0 / 255.0, alpha: 1.0)
        )
        public static let sourceAccent: Color = adaptive(
            light: UIColor(red: 125.0 / 255.0, green: 92.0 / 255.0, blue: 114.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 209.0 / 255.0, green: 162.0 / 255.0, blue: 188.0 / 255.0, alpha: 1.0)
        )
        public static let sourceSurface: Color = adaptive(
            light: UIColor(red: 239.0 / 255.0, green: 227.0 / 255.0, blue: 234.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 64.0 / 255.0, green: 46.0 / 255.0, blue: 58.0 / 255.0, alpha: 1.0)
        )
        public static let sourceBorder: Color = adaptive(
            light: UIColor(red: 125.0 / 255.0, green: 92.0 / 255.0, blue: 114.0 / 255.0, alpha: 0.32),
            dark: UIColor(red: 209.0 / 255.0, green: 162.0 / 255.0, blue: 188.0 / 255.0, alpha: 0.35)
        )
        public static let separator: Color = borderSubtle
        public static let focus: Color = accent

        // MARK: Component-specific semantic aliases
        public static let sourceCardSurface: Color = sourceSurface
        public static let sourceCardBorder: Color = sourceBorder
        public static let sourceCardAccent: Color = sourceAccent
        public static let memoryCardSurface: Color = contentSurface
        public static let memoryCardBorder: Color = separator
        public static let privateBadgeSurface: Color = adaptive(
            light: UIColor(red: 221.0 / 255.0, green: 232.0 / 255.0, blue: 231.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 38.0 / 255.0, green: 59.0 / 255.0, blue: 59.0 / 255.0, alpha: 1.0)
        )
        public static let privateBadgeText: Color = adaptive(
            light: UIColor(red: 63.0 / 255.0, green: 86.0 / 255.0, blue: 90.0 / 255.0, alpha: 1.0),
            dark: UIColor(red: 156.0 / 255.0, green: 197.0 / 255.0, blue: 196.0 / 255.0, alpha: 1.0)
        )
        public static let appLockBackground: Color = backgroundGrouped
        public static let appLockSurface: Color = surfaceElevated
        public static let textDestructive: Color = destructive

        // MARK: Legacy aliases - preserve exact same names so existing code compiles
        public static let primary: Color = brandInk
        public static let background: Color = backgroundGrouped
        public static let surface: Color = surfacePrimary
        public static let successLight: Color = successSoft
        public static let warningLight: Color = warningSoft
        public static let destructiveLight: Color = destructiveSoft
        public static let brandSage: Color = accent
        public static let brandSageSoft: Color = accentSoft
        public static let brandThread: Color = textOnAccent
        public static let brandThreadSoft: Color = textOnAccent.opacity(0.74)
        #else
        // macOS fallbacks use the same semantic roles with native system surfaces.
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
        public static let successSoft: Color = .green.opacity(0.12)
        public static let warningSoft: Color = .orange.opacity(0.12)
        public static let destructiveSoft: Color = .red.opacity(0.12)
        public static let textPrimary: Color = .primary
        public static let textSecondary: Color = .secondary
        public static let textTertiary: Color = .secondary.opacity(0.82)
        public static let textOnAccent: Color = .white
        public static let textOnDestructive: Color = .white
        public static let textDestructive: Color = .red
        public static let accent: Color = brandOlive
        public static let accentSoft: Color = brandOlive.opacity(0.10)
        public static let accentPressed: Color = brandOlive.opacity(0.80)
        public static let accentDisabled: Color = brandOlive.opacity(0.28)
        public static let borderSubtle: Color = Color.primary.opacity(0.09)
        public static let borderStrong: Color = Color.primary.opacity(0.16)
        public static let borderAccent: Color = brandOlive.opacity(0.22)
        public static let borderDestructive: Color = Color.red.opacity(0.30)
        public static let sense: Color = brandViolet
        public static let senseLight: Color = brandViolet.opacity(0.10)
        public static let canvas: Color = backgroundPrimary
        public static let canvasSecondary: Color = backgroundSecondary
        public static let contentSurface: Color = surfacePrimary
        public static let contentSurfaceElevated: Color = surfaceElevated
        public static let controlFallback: Color = surfaceElevated
        public static let glassTint: Color = accent.opacity(0.12)
        public static let glassBorder: Color = borderAccent
        public static let controlAccent: Color = accent
        public static let controlAccentPressed: Color = accentPressed
        public static let sourceAccent: Color = Color(.sRGB, red: 125.0 / 255.0, green: 92.0 / 255.0, blue: 114.0 / 255.0, opacity: 1.0)
        public static let sourceSurface: Color = Color(.sRGB, red: 239.0 / 255.0, green: 227.0 / 255.0, blue: 234.0 / 255.0, opacity: 1.0)
        public static let sourceBorder: Color = sourceAccent.opacity(0.32)
        public static let separator: Color = borderSubtle
        public static let focus: Color = accent
        public static let sourceCardSurface: Color = sourceSurface
        public static let sourceCardBorder: Color = sourceBorder
        public static let sourceCardAccent: Color = sourceAccent
        public static let memoryCardSurface: Color = Color(nsColor: .controlBackgroundColor)
        public static let memoryCardBorder: Color = Color.primary.opacity(0.09)
        public static let privateBadgeSurface: Color = Color(.sRGB, red: 221.0 / 255.0, green: 232.0 / 255.0, blue: 231.0 / 255.0, opacity: 1.0)
        public static let privateBadgeText: Color = Color(.sRGB, red: 63.0 / 255.0, green: 86.0 / 255.0, blue: 90.0 / 255.0, opacity: 1.0)
        public static let appLockBackground: Color = Color(nsColor: .windowBackgroundColor)
        public static let appLockSurface: Color = Color(nsColor: .controlBackgroundColor)
        public static let primary: Color = brandInk
        public static let background: Color = Color(nsColor: .windowBackgroundColor)
        public static let surface: Color = Color(nsColor: .controlBackgroundColor)
        public static let successLight: Color = .green.opacity(0.12)
        public static let warningLight: Color = .orange.opacity(0.12)
        public static let destructiveLight: Color = .red.opacity(0.12)
        public static let brandSage: Color = accent
        public static let brandSageSoft: Color = accentSoft
        public static let brandThread: Color = .white
        public static let brandThreadSoft: Color = Color.white.opacity(0.74)
        #endif
    }

    // MARK: - Materials

    /// Semantic surface roles. Rendering is handled by `View.mnemoSurface` so accessibility fallbacks stay consistent.
    public enum Materials {
        public enum Role: Equatable, Sendable {
            case navigationChrome
            case floatingControl
            case compactControl
            case sheetChrome
            case contentFallback
        }

        public static let navigationChrome: Role = .navigationChrome
        public static let floatingControl: Role = .floatingControl
        public static let compactControl: Role = .compactControl
        public static let sheetChrome: Role = .sheetChrome
        public static let contentFallback: Role = .contentFallback

        public static func opaqueFallback(for role: Role) -> Color {
            switch role {
            case .contentFallback:
                return DS.Colours.contentSurface
            case .navigationChrome, .sheetChrome:
                return DS.Colours.contentSurfaceElevated
            case .floatingControl, .compactControl:
                return DS.Colours.controlFallback
            }
        }
    }

    // MARK: - Typography

    /// SF Pro-backed Dynamic Type scale for consistent hierarchy across Mnemo screens.
    public enum Typography {
        public static let largeTitle: Font = .largeTitle.weight(.bold)
        public static let title1: Font = .title.weight(.semibold)
        public static let title2: Font = .title2.weight(.semibold)
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
        public static let subtle: Shadow = Shadow(opacity: 0.04, radius: 3.0, y: 1.0)
        public static let medium: Shadow = Shadow(opacity: 0.07, radius: 7.0, y: 3.0)
        public static let strong: Shadow = Shadow(opacity: 0.11, radius: 12.0, y: 6.0)
    }

    // MARK: - Animation

    /// Motion timings for feedback, transitions, and spring interactions.
    public enum Animation {
        public static let quick: SwiftUI.Animation = .easeInOut(duration: 0.15)
        public static let standard: SwiftUI.Animation = .easeInOut(duration: 0.24)
        public static let slow: SwiftUI.Animation = .easeInOut(duration: 0.38)
        public static let gentleSpring: SwiftUI.Animation = .spring(response: 0.34, dampingFraction: 0.90)
        public static let emphasisSpring: SwiftUI.Animation = .spring(response: 0.38, dampingFraction: 0.86)
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

        public static let scalePress: CGFloat = 0.985

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
            public static let background: Color = DS.Colours.contentSurface
            public static let border: Color = DS.Colours.separator
            public static let cornerRadius: CGFloat = DS.CornerRadius.medium
            public static let shadow: Shadow = DS.Shadows.subtle
            public static let padding: CGFloat = DS.Spacing.md
        }

        public enum PrimaryButton {
            public static let background: Color = DS.Colours.controlAccent
            public static let foreground: Color = DS.Colours.textOnAccent
            public static let cornerRadius: CGFloat = DS.CornerRadius.medium
            public static let height: CGFloat = 52.0
        }

        public enum SecondaryButton {
            public static let background: Color = DS.Colours.controlFallback
            public static let foreground: Color = DS.Colours.textPrimary
            public static let cornerRadius: CGFloat = DS.CornerRadius.medium
            public static let height: CGFloat = 52.0
        }

        public enum DestructiveButton {
            public static let background: Color = DS.Colours.destructive
            public static let foreground: Color = DS.Colours.textOnDestructive
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
            public static let background: Color = DS.Colours.controlFallback
            public static let cornerRadius: CGFloat = DS.CornerRadius.medium
            public static let height: CGFloat = 48.0
            public static let padding: CGFloat = DS.Spacing.sm
        }

        public enum SourceCard {
            public static let background: Color = DS.Colours.sourceSurface
            public static let border: Color = DS.Colours.sourceBorder
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
            public static let iconForeground: Color = DS.Colours.privateBadgeText
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
