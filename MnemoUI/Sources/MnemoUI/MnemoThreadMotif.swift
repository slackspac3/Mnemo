import SwiftUI

/// A reusable mnemonic-thread motif for calm, non-interactive brand moments.
public struct MnemoThreadMotif: View {
    public enum Style: Equatable {
        case hero
        case watermark
        case source
        case lock
    }

    private let style: Style
    private let tint: Color
    private let lineWidth: CGFloat

    public init(
        style: Style = .watermark,
        tint: Color = DS.Colours.brandSage,
        lineWidth: CGFloat = 2.0
    ) {
        self.style = style
        self.tint = tint
        self.lineWidth = lineWidth
    }

    public var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                if style == .hero || style == .lock {
                    MnemonicThreadShape()
                        .stroke(
                            tint.opacity(0.10),
                            style: StrokeStyle(lineWidth: lineWidth * 2.8, lineCap: .round, lineJoin: .round)
                        )
                        .frame(width: side * 0.88, height: side * 0.88)
                        .scaleEffect(1.18)
                }

                MnemonicThreadShape()
                    .stroke(
                        strokeTint,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: side * 0.78, height: side * 0.78)
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
