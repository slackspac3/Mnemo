import SwiftUI

/// Mnemo's mnemonic-thread mark: a calm continuous line for saved context and recall.
public struct MnemoLogoMark: View {
    public enum Style {
        case filled
        case subtle
        case monochrome
    }

    private let size: CGFloat
    private let style: Style
    @Environment(\.colorScheme) private var colorScheme

    public init(size: CGFloat = 64.0, style: Style = .filled) {
        self.size = size
        self.style = style
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(background)

            MnemoThreadShape()
                .stroke(
                    thread,
                    style: StrokeStyle(
                        lineWidth: max(size * 0.072, 2.5),
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .padding(size * 0.22)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mnemo")
    }

    private var background: Color {
        switch style {
        case .filled:
            return colorScheme == .dark ? DS.Colours.accentPressed : DS.Colours.primary
        case .subtle:
            return DS.Colours.privateBadgeSurface
        case .monochrome:
            return DS.Colours.surfaceSecondary
        }
    }

    private var thread: Color {
        switch style {
        case .filled:
            return .white.opacity(0.94)
        case .subtle:
            return DS.Colours.accent
        case .monochrome:
            return DS.Colours.textPrimary
        }
    }
}

private struct MnemoThreadShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: rect.minX + 0.12 * w, y: rect.minY + 0.58 * h))
        path.addCurve(
            to: CGPoint(x: rect.minX + 0.40 * w, y: rect.minY + 0.30 * h),
            control1: CGPoint(x: rect.minX + 0.16 * w, y: rect.minY + 0.34 * h),
            control2: CGPoint(x: rect.minX + 0.31 * w, y: rect.minY + 0.24 * h)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + 0.62 * w, y: rect.minY + 0.50 * h),
            control1: CGPoint(x: rect.minX + 0.49 * w, y: rect.minY + 0.36 * h),
            control2: CGPoint(x: rect.minX + 0.50 * w, y: rect.minY + 0.50 * h)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + 0.88 * w, y: rect.minY + 0.40 * h),
            control1: CGPoint(x: rect.minX + 0.75 * w, y: rect.minY + 0.50 * h),
            control2: CGPoint(x: rect.minX + 0.80 * w, y: rect.minY + 0.34 * h)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + 0.55 * w, y: rect.minY + 0.78 * h),
            control1: CGPoint(x: rect.minX + 0.94 * w, y: rect.minY + 0.58 * h),
            control2: CGPoint(x: rect.minX + 0.75 * w, y: rect.minY + 0.82 * h)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + 0.30 * w, y: rect.minY + 0.64 * h),
            control1: CGPoint(x: rect.minX + 0.45 * w, y: rect.minY + 0.76 * h),
            control2: CGPoint(x: rect.minX + 0.39 * w, y: rect.minY + 0.66 * h)
        )

        return path
    }
}
