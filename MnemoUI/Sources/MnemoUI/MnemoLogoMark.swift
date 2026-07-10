import SwiftUI

/// Mnemo's closed-notebook mark: private capture held in place for reliable recall.
public struct MnemoLogoMark: View {
    public enum Style {
        case filled
        case subtle
        case monochrome
    }

    private let size: CGFloat
    private let style: Style
    private let overrideTint: Color?

    public init(
        size: CGFloat = 64.0,
        style: Style = .filled,
        tint: Color? = nil
    ) {
        self.size = size
        self.style = style
        self.overrideTint = tint
    }

    public var body: some View {
        Canvas { context, canvasSize in
            let side = min(canvasSize.width, canvasSize.height)
            let origin = CGPoint(
                x: (canvasSize.width - side) / 2.0,
                y: (canvasSize.height - side) / 2.0
            )
            let rect: (CGFloat, CGFloat, CGFloat, CGFloat) -> CGRect = { x, y, width, height in
                CGRect(
                    x: origin.x + side * x / 48.0,
                    y: origin.y + side * y / 48.0,
                    width: side * width / 48.0,
                    height: side * height / 48.0
                )
            }

            let cover = Path(
                roundedRect: rect(13.0, 8.0, 22.0, 32.0),
                cornerRadius: side * 4.5 / 48.0
            )
            context.stroke(
                cover,
                with: .color(resolvedTint),
                style: StrokeStyle(
                    lineWidth: side * 2.4 / 48.0,
                    lineCap: .round,
                    lineJoin: .round
                )
            )

            let band = Path(
                roundedRect: rect(28.0, 8.0, 4.0, 32.0),
                cornerRadius: side * 1.2 / 48.0
            )
            context.fill(band, with: .color(resolvedTint))

            var ribbon = Path()
            ribbon.move(to: point(18.0, 40.0, side: side, origin: origin))
            ribbon.addLine(to: point(18.0, 45.0, side: side, origin: origin))
            ribbon.addLine(to: point(20.5, 43.0, side: side, origin: origin))
            ribbon.addLine(to: point(23.0, 45.0, side: side, origin: origin))
            ribbon.addLine(to: point(23.0, 40.0, side: side, origin: origin))
            ribbon.closeSubpath()
            context.fill(ribbon, with: .color(resolvedTint))
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mnemo")
    }

    private var resolvedTint: Color {
        if let overrideTint {
            return overrideTint
        }

        return switch style {
        case .filled:
            DS.Colours.accent
        case .subtle:
            DS.Colours.accent.opacity(0.58)
        case .monochrome:
            DS.Colours.textPrimary
        }
    }

    private func point(
        _ x: CGFloat,
        _ y: CGFloat,
        side: CGFloat,
        origin: CGPoint
    ) -> CGPoint {
        CGPoint(
            x: origin.x + side * x / 48.0,
            y: origin.y + side * y / 48.0
        )
    }
}

/// The production notebook mark and Newsreader wordmark with one optical ratio and clearspace rule.
public struct MnemoBrandLockup: View {
    private let markSize: CGFloat
    private let markTint: Color
    private let wordmarkTint: Color

    public init(
        markSize: CGFloat = 52.0,
        markTint: Color = DS.Colours.accent,
        wordmarkTint: Color = DS.Colours.textPrimary
    ) {
        self.markSize = markSize
        self.markTint = markTint
        self.wordmarkTint = wordmarkTint
    }

    public var body: some View {
        HStack(spacing: markSize * 0.24) {
            MnemoLogoMark(size: markSize, style: .filled, tint: markTint)
                .accessibilityHidden(true)

            MnemoWordmark(tint: wordmarkTint)
                .frame(width: markSize * 3.38, height: markSize)
                .accessibilityHidden(true)
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mnemo")
    }
}

/// Mnemo wordmark rendered from Newsreader Regular vector outlines (SIL Open Font License 1.1).
public struct MnemoWordmark: View {
    private let tint: Color

    public init(tint: Color = DS.Colours.textPrimary) {
        self.tint = tint
    }

    public var body: some View {
        Canvas { context, size in
            let sourceAspect = 4.781434
            let drawWidth = min(size.width, size.height * sourceAspect)
            let drawHeight = drawWidth / sourceAspect
            let origin = CGPoint(x: (size.width - drawWidth) / 2.0, y: (size.height - drawHeight) / 2.0)
            let point: (CGFloat, CGFloat) -> CGPoint = { x, y in
                CGPoint(x: origin.x + drawWidth * x, y: origin.y + drawHeight * y)
            }
            var path = Path()
            path.move(to: point(0.260202, 0.937241))
            path.addLine(to: point(0.286020, 0.966207))
            path.addLine(to: point(0.286020, 0.986207))
            path.addLine(to: point(0.204094, 0.986207))
            path.addLine(to: point(0.204094, 0.966207))
            path.addLine(to: point(0.229912, 0.937241))
            path.addLine(to: point(0.216210, 0.071034))
            path.addLine(to: point(0.218229, 0.072414))
            path.addLine(to: point(0.136736, 1.000000))
            path.addLine(to: point(0.131832, 1.000000))
            path.addLine(to: point(0.044425, 0.095862))
            path.addLine(to: point(0.046444, 0.093793))
            path.addLine(to: point(0.034905, 0.937241))
            path.addLine(to: point(0.063608, 0.966207))
            path.addLine(to: point(0.063608, 0.986207))
            path.addLine(to: point(0.000000, 0.986207))
            path.addLine(to: point(0.000000, 0.966207))
            path.addLine(to: point(0.025818, 0.937241))
            path.addLine(to: point(0.037790, 0.064828))
            path.addLine(to: point(0.011395, 0.020000))
            path.addLine(to: point(0.011395, 0.000000))
            path.addLine(to: point(0.067214, 0.000000))
            path.addLine(to: point(0.147842, 0.835172))
            path.addLine(to: point(0.142361, 0.835172))
            path.addLine(to: point(0.215056, 0.000000))
            path.addLine(to: point(0.273904, 0.000000))
            path.addLine(to: point(0.273904, 0.020000))
            path.addLine(to: point(0.245346, 0.048276))
            path.closeSubpath()
            path.move(to: point(0.340905, 0.393103))
            path.addLine(to: point(0.340905, 0.946897))
            path.addLine(to: point(0.361531, 0.967586))
            path.addLine(to: point(0.361531, 0.986207))
            path.addLine(to: point(0.293740, 0.986207))
            path.addLine(to: point(0.293740, 0.967586))
            path.addLine(to: point(0.314365, 0.946897))
            path.addLine(to: point(0.314365, 0.395862))
            path.addCurve(
                to: point(0.307803, 0.376207),
                control1: point(0.312827, 0.391264),
                control2: point(0.310639, 0.384713)
            )
            path.addCurve(
                to: point(0.293740, 0.333793),
                control1: point(0.304966, 0.367701),
                control2: point(0.300278, 0.353563)
            )
            path.addLine(to: point(0.293740, 0.321379))
            path.addLine(to: point(0.340328, 0.258621))
            path.addLine(to: point(0.340905, 0.258621))
            path.closeSubpath()
            path.move(to: point(0.387060, 0.967586))
            path.addLine(to: point(0.407830, 0.946897))
            path.addLine(to: point(0.407830, 0.503448))
            path.addCurve(
                to: point(0.376243, 0.364138),
                control1: point(0.407830, 0.411034),
                control2: point(0.398166, 0.364138)
            )
            path.addCurve(
                to: point(0.337443, 0.409655),
                control1: point(0.361050, 0.364138),
                control2: point(0.346482, 0.388506)
            )
            path.addLine(to: point(0.335568, 0.395172))
            path.addCurve(
                to: point(0.369896, 0.290345),
                control1: point(0.350569, 0.341839),
                control2: point(0.361242, 0.308736)
            )
            path.addCurve(
                to: point(0.394416, 0.266207),
                control1: point(0.378550, 0.271954),
                control2: point(0.385762, 0.266207)
            )
            path.addCurve(
                to: point(0.434370, 0.491724),
                control1: point(0.422687, 0.266207),
                control2: point(0.434370, 0.335402)
            )
            path.addLine(to: point(0.434370, 0.946897))
            path.addLine(to: point(0.454995, 0.967586))
            path.addLine(to: point(0.454995, 0.986207))
            path.addLine(to: point(0.387060, 0.986207))
            path.closeSubpath()
            path.move(to: point(0.535987, 0.266207))
            path.addCurve(
                to: point(0.588200, 0.528276),
                control1: point(0.566276, 0.266207),
                control2: point(0.585604, 0.357241)
            )
            path.addLine(to: point(0.492716, 0.528276))
            path.addLine(to: point(0.492716, 0.488276))
            path.addLine(to: point(0.572334, 0.488276))
            path.addLine(to: point(0.561084, 0.515862))
            path.addCurve(
                to: point(0.531660, 0.300000),
                control1: point(0.558199, 0.366897),
                control2: point(0.548968, 0.300000)
            )
            path.addCurve(
                to: point(0.494303, 0.575862),
                control1: point(0.508294, 0.300000),
                control2: point(0.494303, 0.400690)
            )
            path.addCurve(
                to: point(0.547958, 0.901379),
                control1: point(0.494303, 0.806207),
                control2: point(0.513630, 0.901379)
            )
            path.addCurve(
                to: point(0.589354, 0.808276),
                control1: point(0.563824, 0.901379),
                control2: point(0.579835, 0.870345)
            )
            path.addLine(to: point(0.591662, 0.815862))
            path.addCurve(
                to: point(0.533246, 1.000000),
                control1: point(0.573777, 0.952414),
                control2: point(0.556613, 1.000000)
            )
            path.addCurve(
                to: point(0.475624, 0.840345),
                control1: point(0.508245, 1.000000),
                control2: point(0.487259, 0.945632)
            )
            path.addCurve(
                to: point(0.466898, 0.645517),
                control1: point(0.469807, 0.787701),
                control2: point(0.466898, 0.722759)
            )
            path.addCurve(
                to: point(0.498702, 0.318276),
                control1: point(0.466898, 0.508506),
                control2: point(0.478028, 0.387701)
            )
            path.addCurve(
                to: point(0.535987, 0.266207),
                control1: point(0.509039, 0.283563),
                control2: point(0.521467, 0.266207)
            )
            path.closeSubpath()
            path.move(to: point(0.649143, 0.393103))
            path.addLine(to: point(0.649143, 0.946897))
            path.addLine(to: point(0.669769, 0.967586))
            path.addLine(to: point(0.669769, 0.986207))
            path.addLine(to: point(0.601978, 0.986207))
            path.addLine(to: point(0.601978, 0.967586))
            path.addLine(to: point(0.622604, 0.946897))
            path.addLine(to: point(0.622604, 0.395862))
            path.addCurve(
                to: point(0.616041, 0.376207),
                control1: point(0.621065, 0.391264),
                control2: point(0.618877, 0.384713)
            )
            path.addCurve(
                to: point(0.601978, 0.333793),
                control1: point(0.613204, 0.367701),
                control2: point(0.608516, 0.353563)
            )
            path.addLine(to: point(0.601978, 0.321379))
            path.addLine(to: point(0.648566, 0.258621))
            path.addLine(to: point(0.649143, 0.258621))
            path.closeSubpath()
            path.move(to: point(0.736838, 0.478621))
            path.addLine(to: point(0.736838, 0.946897))
            path.addLine(to: point(0.757464, 0.967586))
            path.addLine(to: point(0.757464, 0.986207))
            path.addLine(to: point(0.689529, 0.986207))
            path.addLine(to: point(0.689529, 0.967586))
            path.addLine(to: point(0.710299, 0.946897))
            path.addLine(to: point(0.710299, 0.492414))
            path.addCurve(
                to: point(0.681163, 0.364138),
                control1: point(0.710299, 0.406897),
                control2: point(0.701356, 0.364138)
            )
            path.addCurve(
                to: point(0.645537, 0.406207),
                control1: point(0.667509, 0.364138),
                control2: point(0.653999, 0.385977)
            )
            path.addLine(to: point(0.643806, 0.387586))
            path.addCurve(
                to: point(0.699193, 0.266207),
                control1: point(0.672269, 0.286437),
                control2: point(0.683038, 0.266207)
            )
            path.addCurve(
                to: point(0.736838, 0.478621),
                control1: point(0.725732, 0.266207),
                control2: point(0.736838, 0.331034)
            )
            path.closeSubpath()
            path.move(to: point(0.824534, 0.478621))
            path.addLine(to: point(0.824534, 0.946897))
            path.addLine(to: point(0.845160, 0.967586))
            path.addLine(to: point(0.845160, 0.986207))
            path.addLine(to: point(0.777225, 0.986207))
            path.addLine(to: point(0.777225, 0.967586))
            path.addLine(to: point(0.797995, 0.946897))
            path.addLine(to: point(0.797995, 0.492414))
            path.addCurve(
                to: point(0.768859, 0.364138),
                control1: point(0.797995, 0.406897),
                control2: point(0.789052, 0.364138)
            )
            path.addCurve(
                to: point(0.733233, 0.406207),
                control1: point(0.755205, 0.364138),
                control2: point(0.741694, 0.385977)
            )
            path.addLine(to: point(0.731502, 0.387586))
            path.addCurve(
                to: point(0.786888, 0.266207),
                control1: point(0.759964, 0.286437),
                control2: point(0.770734, 0.266207)
            )
            path.addCurve(
                to: point(0.824534, 0.478621),
                control1: point(0.813428, 0.266207),
                control2: point(0.824534, 0.330575)
            )
            path.closeSubpath()
            path.move(to: point(0.928026, 0.969655))
            path.addCurve(
                to: point(0.970720, 0.633793),
                control1: point(0.956008, 0.969655),
                control2: point(0.970720, 0.854483)
            )
            path.addCurve(
                to: point(0.928892, 0.296552),
                control1: point(0.970720, 0.411724),
                control2: point(0.956296, 0.296552)
            )
            path.addCurve(
                to: point(0.886198, 0.632414),
                control1: point(0.900910, 0.296552),
                control2: point(0.886198, 0.411724)
            )
            path.addCurve(
                to: point(0.928026, 0.969655),
                control1: point(0.886198, 0.853103),
                control2: point(0.900621, 0.969655)
            )
            path.closeSubpath()
            path.move(to: point(0.927738, 1.000000))
            path.addCurve(
                to: point(0.866437, 0.823103),
                control1: point(0.901583, 1.000000),
                control2: point(0.879130, 0.933908)
            )
            path.addCurve(
                to: point(0.856918, 0.632414),
                control1: point(0.860091, 0.767701),
                control2: point(0.856918, 0.704138)
            )
            path.addCurve(
                to: point(0.866654, 0.442069),
                control1: point(0.856918, 0.560690),
                control2: point(0.860163, 0.497241)
            )
            path.addCurve(
                to: point(0.929180, 0.266207),
                control1: point(0.879635, 0.331724),
                control2: point(0.902448, 0.266207)
            )
            path.addCurve(
                to: point(0.990625, 0.442759),
                control1: point(0.955912, 0.266207),
                control2: point(0.978124, 0.332414)
            )
            path.addCurve(
                to: point(1.000000, 0.633793),
                control1: point(0.996875, 0.497931),
                control2: point(1.000000, 0.561609)
            )
            path.addCurve(
                to: point(0.990120, 0.824138),
                control1: point(1.000000, 0.705517),
                control2: point(0.996707, 0.768966)
            )
            path.addCurve(
                to: point(0.963797, 0.953448),
                control1: point(0.983533, 0.879310),
                control2: point(0.974759, 0.922414)
            )
            path.addCurve(
                to: point(0.927738, 1.000000),
                control1: point(0.952835, 0.984483),
                control2: point(0.940815, 1.000000)
            )
            path.closeSubpath()
            context.fill(path, with: .color(tint), style: FillStyle(eoFill: true))
        }
        .aspectRatio(4.781434, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mnemo")
    }
}
