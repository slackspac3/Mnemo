#if DEBUG
import SwiftUI
import MnemoUI

struct DesignExplorationView: View {
    var body: some View {
        List {
            Section("Palette") {
                DesignSwatch(name: "Canvas", color: DS.Colours.canvas)
                DesignSwatch(name: "Content", color: DS.Colours.contentSurface)
                DesignSwatch(name: "Memory accent", color: DS.Colours.accent)
                DesignSwatch(name: "Control accent", color: DS.Colours.controlAccent)
                DesignSwatch(name: "Source", color: DS.Colours.sourceAccent)
                DesignSwatch(name: "Destructive", color: DS.Colours.destructive)
            }

            Section("Controls") {
                Button("Primary Action") {}
                    .buttonStyle(.mnemoPrimary)

                Button("Secondary Action") {}
                    .buttonStyle(.mnemoSecondary)

                Label("Looking through your memories", systemImage: "bookmark")
                    .font(DS.Typography.footnote)
                    .foregroundStyle(DS.Colours.textSecondary)
                    .padding(DS.Spacing.md)
                    .mnemoSurface(.compactControl)
            }

            Section("Source Evidence") {
                HStack(alignment: .top, spacing: DS.Spacing.sm) {
                    Image(systemName: "doc.text")
                        .foregroundStyle(DS.Colours.sourceAccent)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text("Text memory")
                            .font(DS.Typography.caption1.weight(.semibold))
                            .foregroundStyle(DS.Colours.sourceAccent)
                        Text("The waterfall I loved was in Guam.")
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Colours.textPrimary)
                    }
                }
                .mnemoSourceCard()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Text memory source. The waterfall I loved was in Guam.")
            }

            Section("Mnemonic Thread Concept") {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    HStack(spacing: DS.Spacing.lg) {
                        ForEach([24.0, 32.0, 60.0], id: \.self) { size in
                            VStack(spacing: DS.Spacing.xs) {
                                RefinedMnemonicThreadConcept()
                                    .stroke(
                                        DS.Colours.textPrimary,
                                        style: StrokeStyle(lineWidth: max(2.0, size * 0.075), lineCap: .round, lineJoin: .round)
                                    )
                                    .frame(width: size, height: size)
                                    .accessibilityHidden(true)

                                Text("\(Int(size))")
                                    .font(DS.Typography.caption2)
                                    .foregroundStyle(DS.Colours.textSecondary)
                            }
                        }
                    }

                    HStack(spacing: DS.Spacing.md) {
                        conceptTile(color: DS.Colours.textPrimary, label: "Mono")
                        conceptTile(color: DS.Colours.accent, label: "Tinted")
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Refined mnemonic thread concept in small, monochrome, and tinted presentations")
            }
        }
        .scrollContentBackground(.hidden)
        .background(DS.Colours.canvas)
        .navigationTitle("Design Exploration")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func conceptTile(color: Color, label: String) -> some View {
        VStack(spacing: DS.Spacing.sm) {
            RefinedMnemonicThreadConcept()
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 7.0, lineCap: .round, lineJoin: .round)
                )
                .frame(width: 88.0, height: 88.0)

            Text(label)
                .font(DS.Typography.caption1)
                .foregroundStyle(DS.Colours.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DS.Spacing.md)
        .background(DS.Colours.contentSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
    }
}

private struct DesignSwatch: View {
    let name: String
    let color: Color

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            RoundedRectangle(cornerRadius: DS.CornerRadius.small)
                .fill(color)
                .frame(width: 44.0, height: 44.0)
                .overlay {
                    RoundedRectangle(cornerRadius: DS.CornerRadius.small)
                        .stroke(DS.Colours.borderStrong, lineWidth: 1.0)
                }
                .accessibilityHidden(true)

            Text(name)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textPrimary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(name)
    }
}

private struct RefinedMnemonicThreadConcept: Shape {
    func path(in rect: CGRect) -> Path {
        let point: (CGFloat, CGFloat) -> CGPoint = { x, y in
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }

        var path = Path()
        path.move(to: point(0.10, 0.62))
        path.addCurve(
            to: point(0.34, 0.34),
            control1: point(0.14, 0.32),
            control2: point(0.24, 0.24)
        )
        path.addCurve(
            to: point(0.52, 0.58),
            control1: point(0.42, 0.42),
            control2: point(0.44, 0.60)
        )
        path.addCurve(
            to: point(0.78, 0.38),
            control1: point(0.62, 0.58),
            control2: point(0.66, 0.34)
        )
        path.addCurve(
            to: point(0.90, 0.56),
            control1: point(0.86, 0.38),
            control2: point(0.91, 0.46)
        )
        path.addCurve(
            to: point(0.58, 0.82),
            control1: point(0.86, 0.76),
            control2: point(0.72, 0.86)
        )
        path.addCurve(
            to: point(0.20, 0.72),
            control1: point(0.42, 0.82),
            control2: point(0.28, 0.76)
        )
        return path
    }
}

#Preview("Light") {
    NavigationStack {
        DesignExplorationView()
    }
}

#Preview("Dark") {
    NavigationStack {
        DesignExplorationView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Accessibility Type") {
    NavigationStack {
        DesignExplorationView()
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}

#endif
