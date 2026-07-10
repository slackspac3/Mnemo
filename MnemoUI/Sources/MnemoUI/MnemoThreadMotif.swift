import SwiftUI

/// A compatibility wrapper for calm, non-interactive Notebook brand moments.
@available(*, deprecated, message: "Use MnemoLogoMark for Notebook brand moments.")
public struct MnemoThreadMotif: View {
    public enum Style: Equatable {
        case hero
        case watermark
        case source
        case lock
    }

    private let style: Style
    private let tint: Color

    public init(
        style: Style = .watermark,
        tint: Color = DS.Colours.brandSage,
        lineWidth: CGFloat = 2.0
    ) {
        self.style = style
        self.tint = tint
        _ = lineWidth
    }

    public var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                if style == .hero || style == .lock {
                    MnemoLogoMark(
                        size: side * 0.88,
                        style: .filled,
                        tint: tint.opacity(0.10)
                    )
                        .scaleEffect(1.18)
                }

                MnemoLogoMark(
                    size: side * 0.78,
                    style: .filled,
                    tint: strokeTint
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private var strokeTint: Color {
        switch style {
        case .hero:
            return tint.opacity(0.24)
        case .watermark:
            return tint.opacity(0.12)
        case .source:
            return DS.Colours.sourceCardAccent.opacity(0.18)
        case .lock:
            return tint.opacity(0.18)
        }
    }
}
