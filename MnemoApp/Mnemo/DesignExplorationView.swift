#if DEBUG
import SwiftUI
import MnemoUI

struct DesignExplorationView: View {
    var body: some View {
        List {
            Section("Palette") {
                DesignSwatch(name: "Canvas", color: DS.Colours.canvas)
                DesignSwatch(name: "Content", color: DS.Colours.contentSurface)
                DesignSwatch(name: "Action and focus", color: DS.Colours.accent)
                DesignSwatch(name: "Filled control", color: DS.Colours.controlAccent)
                DesignSwatch(name: "Source evidence", color: DS.Colours.sourceAccent)
                DesignSwatch(name: "Privacy", color: DS.Colours.privateBadgeText)
                DesignSwatch(name: "Destructive", color: DS.Colours.destructive)
            }

            Section("Semantic Roles") {
                Button("Primary Action") {}
                    .buttonStyle(.mnemoPrimary)

                Label("Private on this iPhone", systemImage: "lock.shield.fill")
                    .font(DS.Typography.footnote.weight(.semibold))
                    .foregroundStyle(DS.Colours.privateBadgeText)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.sm)
                    .background(DS.Colours.privateBadgeSurface)
                    .clipShape(Capsule())

                sourceEvidenceSample
            }

            Section("Identity Review") {
                NavigationLink {
                    NotebookMarkGallery()
                } label: {
                    Label("The Notebook mark", systemImage: "book.closed")
                }

                Text("The approved N-A mark, wordmark, AccentColor, and AppIcon variants are now installed in the production identity.")
                    .font(DS.Typography.footnote)
                    .foregroundStyle(DS.Colours.textSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(DS.Colours.canvas)
        .navigationTitle("Design Exploration")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sourceEvidenceSample: some View {
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
}

private struct NotebookMarkGallery: View {
    private let markSizes: [CGFloat] = [24.0, 32.0, 60.0]
    private let iconSizes: [CGFloat] = [29.0, 44.0, 60.0, 120.0, 180.0]

    var body: some View {
        ZStack {
            DS.Colours.canvas.ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: DS.Spacing.xl) {
                gallerySection("Approval status") {
                    Label("Approved N-A · Production identity installed", systemImage: "checkmark.shield")
                        .font(DS.Typography.subheadline.weight(.semibold))
                        .foregroundStyle(DS.Colours.privateBadgeText)
                        .padding(DS.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DS.Colours.privateBadgeSurface)
                        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                }

                gallerySection("Light and dark candidates") {
                    VStack(spacing: DS.Spacing.md) {
                        ForEach(NotebookVariant.allCases, id: \.self) { variant in
                            NotebookVariantComparison(variant: variant)
                        }
                    }
                }

                gallerySection("Mark legibility") {
                    ScrollView(.horizontal) {
                        HStack(alignment: .top, spacing: DS.Spacing.lg) {
                            ForEach(NotebookVariant.allCases, id: \.self) { variant in
                                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                                    Text(variant.shortTitle)
                                        .font(DS.Typography.caption1.weight(.semibold))
                                        .foregroundStyle(DS.Colours.textPrimary)

                                    HStack(alignment: .bottom, spacing: DS.Spacing.sm) {
                                        ForEach(markSizes, id: \.self) { size in
                                            VStack(spacing: DS.Spacing.xs) {
                                                NotebookReviewMark(variant: variant, tint: DS.Colours.accent)
                                                    .frame(width: size, height: size)
                                                    .frame(width: 60.0, height: 64.0)

                                                Text("\(Int(size)) pt")
                                                    .font(DS.Typography.caption2)
                                                    .foregroundStyle(DS.Colours.textSecondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, DS.Spacing.xs)
                    }
                    .scrollIndicators(.hidden)
                }

                gallerySection("Simulated icon presentations") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Spacing.md) {
                        NotebookPresentationTile(mode: .light)
                        NotebookPresentationTile(mode: .dark)
                        NotebookPresentationTile(mode: .monochrome)
                        NotebookPresentationTile(mode: .tinted)
                    }
                }

                gallerySection("Complete icon sizes") {
                    ScrollView(.horizontal) {
                        HStack(alignment: .bottom, spacing: DS.Spacing.lg) {
                            ForEach(iconSizes, id: \.self) { size in
                                VStack(spacing: DS.Spacing.sm) {
                                    NotebookIconTile(mode: .light, variant: .bandAndRibbon)
                                        .frame(width: size, height: size)

                                    Text("\(Int(size)) pt")
                                        .font(DS.Typography.caption2)
                                        .foregroundStyle(DS.Colours.textSecondary)
                                }
                                .frame(minWidth: max(size, 52.0))
                            }
                        }
                        .padding(.vertical, DS.Spacing.xs)
                    }
                    .scrollIndicators(.hidden)
                }

                gallerySection("Wordmark and lockup") {
                    NotebookBrandLockup(mode: .light)
                    NotebookBrandLockup(mode: .dark)
                }

                gallerySection("Icon in context") {
                    NotebookHomeScreenPreview()
                    NotebookSurfaceContextPreview()
                }

                gallerySection("Accessibility review") {
                    NotebookAccessibilityStatus()
                    NotebookAccessibilityComparison()
                }

                gallerySection("Construction and 1024 master") {
                    NotebookConstructionView()
                        .frame(maxWidth: .infinity)

                    NotebookIconTile(mode: .light, variant: .bandAndRibbon)
                        .frame(width: 280.0, height: 280.0)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Fit-to-screen overview of the light default 1024-point master")

                    NavigationLink("Open 1024 pt master at 1:1") {
                        NotebookLargeInspectionView()
                    }
                    .font(DS.Typography.body.weight(.semibold))

                    Text("Production Default, Dark, and Tinted assets are rendered from editable SVG masters. A canonical .icon document and Clear renders require human review in Icon Composer.")
                        .font(DS.Typography.footnote)
                        .foregroundStyle(DS.Colours.textSecondary)
                }
                }
                .padding(DS.Spacing.md)
            }
        }
        .toolbarBackground(DS.Colours.canvas, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationTitle("Notebook Mark")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func gallerySection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text(title)
                .font(DS.Typography.title3)
                .foregroundStyle(DS.Colours.textPrimary)
                .accessibilityAddTraits(.isHeader)

            content()
        }
    }
}

private struct NotebookVariantComparison: View {
    let variant: NotebookVariant

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text(variant.title)
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Colours.textPrimary)

            HStack(spacing: DS.Spacing.md) {
                NotebookCandidateTile(variant: variant, mode: .light)
                NotebookCandidateTile(variant: variant, mode: .dark)
            }

            Text(variant.summary)
                .font(DS.Typography.footnote)
                .foregroundStyle(DS.Colours.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Spacing.md)
        .background(DS.Colours.contentSurface)
        .overlay {
            RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                .stroke(DS.Colours.separator, lineWidth: 1.0)
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(variant.title). \(variant.summary)")
    }
}

private struct NotebookCandidateTile: View {
    let variant: NotebookVariant
    let mode: NotebookPresentation

    var body: some View {
        VStack(spacing: DS.Spacing.xs) {
            ZStack {
                mode.background
                NotebookReviewMark(
                    variant: variant,
                    tint: mode.tint,
                    evidenceTint: mode.evidenceTint
                )
                .frame(width: 60.0, height: 60.0)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 88.0)
            .clipShape(RoundedRectangle(cornerRadius: 18.0, style: .continuous))

            Text(mode.title)
                .font(DS.Typography.caption2)
                .foregroundStyle(DS.Colours.textSecondary)
        }
    }
}

private struct NotebookPresentationTile: View {
    let mode: NotebookPresentation

    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            NotebookIconTile(mode: mode, variant: .bandAndRibbon)
                .aspectRatio(1.0, contentMode: .fit)

            Text("\(mode.title) simulation")
                .font(DS.Typography.caption1.weight(.semibold))
                .foregroundStyle(DS.Colours.textSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("N-A Notebook mark, simulated \(mode.title) icon presentation")
    }
}

private struct NotebookIconTile: View {
    let mode: NotebookPresentation
    let variant: NotebookVariant

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)

            ZStack {
                mode.background

                NotebookReviewMark(
                    variant: variant,
                    tint: mode.tint,
                    evidenceTint: mode.evidenceTint
                )
                .frame(width: side * 0.58, height: side * 0.58)
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: side * 0.22, style: .continuous))
        }
        .aspectRatio(1.0, contentMode: .fit)
    }
}

private struct NotebookBrandLockup: View {
    let mode: NotebookPresentation

    var body: some View {
        HStack {
            MnemoBrandLockup(
                markSize: 52.0,
                markTint: mode.tint,
                wordmarkTint: mode.labelTint
            )
            Spacer(minLength: 0.0)
        }
        .padding(DS.Spacing.md)
        .background(
            mode == .dark
                ? Color(.sRGB, red: 19.0 / 255.0, green: 23.0 / 255.0, blue: 17.0 / 255.0, opacity: 1.0)
                : Color(.sRGB, red: 252.0 / 255.0, green: 253.0 / 255.0, blue: 249.0 / 255.0, opacity: 1.0)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mnemo Notebook mark and Newsreader wordmark, \(mode.title) appearance")
    }
}

private struct NotebookHomeScreenPreview: View {
    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.lg) {
            HomeScreenIcon(label: "Mnemo", mode: .light, showsNotebook: true)
            HomeScreenIcon(label: "Notes", mode: .dark, showsNotebook: false)
            HomeScreenIcon(label: "Files", mode: .monochrome, showsNotebook: false)
        }
        .padding(DS.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color(.sRGB, red: 43.0 / 255.0, green: 59.0 / 255.0, blue: 61.0 / 255.0, opacity: 1.0))
        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Simulated Home Screen with Mnemo Notebook icon beside neutral app icons")
    }
}

private struct HomeScreenIcon: View {
    let label: String
    let mode: NotebookPresentation
    let showsNotebook: Bool

    var body: some View {
        VStack(spacing: DS.Spacing.xs) {
            if showsNotebook {
                NotebookIconTile(mode: mode, variant: .bandAndRibbon)
                    .frame(width: 58.0, height: 58.0)
            } else {
                RoundedRectangle(cornerRadius: 13.0, style: .continuous)
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 58.0, height: 58.0)
            }

            Text(label)
                .font(DS.Typography.caption2)
                .foregroundStyle(Color.white)
        }
    }
}

private struct NotebookSurfaceContextPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            HStack(spacing: DS.Spacing.sm) {
                NotebookReviewMark(variant: .bandAndRibbon, tint: DS.Colours.accent)
                    .frame(width: 24.0, height: 24.0)
                Text("Mnemo")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colours.textPrimary)
                Spacer(minLength: 0.0)
                Image(systemName: "gearshape")
                    .foregroundStyle(DS.Colours.accent)
            }

            HStack(spacing: DS.Spacing.md) {
                NotebookReviewMark(variant: .bandAndRibbon, tint: DS.Colours.accent)
                    .frame(width: 44.0, height: 44.0)
                Text("What should Mnemo remember?")
                    .font(DS.Typography.title3)
                    .foregroundStyle(DS.Colours.textPrimary)
            }

            HStack(spacing: DS.Spacing.md) {
                NotebookReviewMark(variant: .bandAndRibbon, tint: DS.Colours.accent)
                    .frame(width: 72.0, height: 72.0)
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("Mnemo is locked")
                        .font(DS.Typography.headline)
                        .foregroundStyle(DS.Colours.textPrimary)
                    Label("Protected on this device", systemImage: "lock.shield.fill")
                        .font(DS.Typography.footnote)
                        .foregroundStyle(DS.Colours.privateBadgeText)
                }
            }
        }
        .padding(DS.Spacing.md)
        .background(DS.Colours.contentSurface)
        .overlay {
            RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                .stroke(DS.Colours.separator, lineWidth: 1.0)
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Notebook mark in toolbar, Recall empty state, and App Lock contexts")
    }
}

private struct NotebookAccessibilityStatus: View {
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            NotebookReviewMark(variant: .bandAndRibbon, tint: DS.Colours.accent)
                .frame(width: 44.0, height: 44.0)

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text("System accessibility rendering")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textPrimary)
                Text("Contrast \(contrast == .increased ? "increased" : "standard") · Transparency \(reduceTransparency ? "reduced" : "standard")")
                    .font(DS.Typography.footnote)
                    .foregroundStyle(DS.Colours.textSecondary)
            }
            Spacer(minLength: 0.0)
        }
        .padding(DS.Spacing.md)
        .background(DS.Colours.contentSurface)
        .overlay {
            RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                .stroke(DS.Colours.borderStrong, lineWidth: 1.0)
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("N-A Notebook mark. System accessibility rendering. Contrast \(contrast == .increased ? "increased" : "standard"). Transparency \(reduceTransparency ? "reduced" : "standard").")
    }
}

private struct NotebookAccessibilityComparison: View {
    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            accessibilityTile(
                title: "Increased Contrast",
                background: Color.white,
                tint: Color.black,
                border: Color.black
            )
            accessibilityTile(
                title: "Opaque fallback",
                background: DS.Colours.contentSurfaceElevated,
                tint: DS.Colours.accent,
                border: DS.Colours.borderStrong
            )
        }
    }

    private func accessibilityTile(
        title: String,
        background: Color,
        tint: Color,
        border: Color
    ) -> some View {
        VStack(spacing: DS.Spacing.sm) {
            NotebookReviewMark(variant: .bandAndRibbon, tint: tint)
                .frame(width: 52.0, height: 52.0)
            Text(title)
                .font(DS.Typography.caption1.weight(.semibold))
                .foregroundStyle(tint)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 112.0)
        .padding(DS.Spacing.sm)
        .background(background)
        .overlay {
            RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                .stroke(border, lineWidth: 1.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("N-A Notebook mark, \(title) review")
    }
}

private struct NotebookConstructionView: View {
    var body: some View {
        ZStack {
            DS.Colours.contentSurface

            Canvas { context, size in
                let step = size.width / 8.0
                var grid = Path()
                for index in 1..<8 {
                    let position = CGFloat(index) * step
                    grid.move(to: CGPoint(x: position, y: 0.0))
                    grid.addLine(to: CGPoint(x: position, y: size.height))
                    grid.move(to: CGPoint(x: 0.0, y: position))
                    grid.addLine(to: CGPoint(x: size.width, y: position))
                }
                context.stroke(grid, with: .color(DS.Colours.borderSubtle), lineWidth: 0.5)

                let safeRect = CGRect(x: size.width * 0.21, y: size.height * 0.21, width: size.width * 0.58, height: size.height * 0.58)
                context.stroke(Path(safeRect), with: .color(DS.Colours.accent), style: StrokeStyle(lineWidth: 1.0, dash: [4.0, 4.0]))
            }

            NotebookReviewMark(variant: .bandAndRibbon, tint: DS.Colours.accent)
                .frame(width: 150.0, height: 150.0)
        }
        .frame(width: 260.0, height: 260.0)
        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
        .overlay {
            RoundedRectangle(cornerRadius: DS.CornerRadius.large)
                .stroke(DS.Colours.borderStrong, lineWidth: 1.0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("N-A Notebook construction grid with a 58 percent central artwork area and 21 percent margin on each side")
    }
}

private struct NotebookLargeInspectionView: View {
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            NotebookIconTile(mode: .light, variant: .bandAndRibbon)
            .frame(width: 1024.0, height: 1024.0)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Light default N-A Notebook icon master at 1024 points, shown one-to-one")
        }
        .background(DS.Colours.canvas.ignoresSafeArea())
        .toolbarBackground(DS.Colours.canvas, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationTitle("1024 pt N-A")
        .navigationBarTitleDisplayMode(.inline)
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

private enum NotebookVariant: String, CaseIterable, Hashable {
    case bandAndRibbon
    case ribbonOnly
    case evidenceRibbon

    var title: String {
        switch self {
        case .bandAndRibbon: "N-A · Band and ribbon"
        case .ribbonOnly: "N-B · Ribbon only"
        case .evidenceRibbon: "N-C · Evidence ribbon"
        }
    }

    var shortTitle: String {
        switch self {
        case .bandAndRibbon: "N-A"
        case .ribbonOnly: "N-B"
        case .evidenceRibbon: "N-C"
        }
    }

    var summary: String {
        switch self {
        case .bandAndRibbon: "Lead direction with the complete notebook silhouette."
        case .ribbonOnly: "Simplified fallback if the band loses clarity at 29 points."
        case .evidenceRibbon: "Plum ribbon for in-content brand moments, not the app icon."
        }
    }
}

private enum NotebookPresentation: Equatable {
    case light
    case dark
    case monochrome
    case tinted

    var title: String {
        switch self {
        case .light: "Light"
        case .dark: "Dark"
        case .monochrome: "Monochrome"
        case .tinted: "Tinted"
        }
    }

    var tint: Color {
        switch self {
        case .light: Color(.sRGB, red: 92.0 / 255.0, green: 104.0 / 255.0, blue: 56.0 / 255.0, opacity: 1.0)
        case .dark: Color(.sRGB, red: 184.0 / 255.0, green: 201.0 / 255.0, blue: 138.0 / 255.0, opacity: 1.0)
        case .monochrome: Color(.sRGB, red: 242.0 / 255.0, green: 245.0 / 255.0, blue: 237.0 / 255.0, opacity: 1.0)
        case .tinted: Color(.sRGB, red: 63.0 / 255.0, green: 74.0 / 255.0, blue: 36.0 / 255.0, opacity: 1.0)
        }
    }

    var evidenceTint: Color {
        switch self {
        case .dark:
            Color(.sRGB, red: 209.0 / 255.0, green: 162.0 / 255.0, blue: 188.0 / 255.0, opacity: 1.0)
        case .light, .tinted:
            Color(.sRGB, red: 125.0 / 255.0, green: 92.0 / 255.0, blue: 114.0 / 255.0, opacity: 1.0)
        case .monochrome:
            tint
        }
    }

    var labelTint: Color {
        switch self {
        case .dark, .monochrome: Color(.sRGB, red: 242.0 / 255.0, green: 245.0 / 255.0, blue: 237.0 / 255.0, opacity: 1.0)
        case .light, .tinted: Color(.sRGB, red: 35.0 / 255.0, green: 40.0 / 255.0, blue: 32.0 / 255.0, opacity: 1.0)
        }
    }

    @ViewBuilder
    var background: some View {
        switch self {
        case .light:
            LinearGradient(
                colors: [
                    Color(.sRGB, red: 252.0 / 255.0, green: 253.0 / 255.0, blue: 249.0 / 255.0, opacity: 1.0),
                    Color(.sRGB, red: 228.0 / 255.0, green: 234.0 / 255.0, blue: 214.0 / 255.0, opacity: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dark:
            LinearGradient(
                colors: [
                    Color(.sRGB, red: 29.0 / 255.0, green: 35.0 / 255.0, blue: 26.0 / 255.0, opacity: 1.0),
                    Color(.sRGB, red: 19.0 / 255.0, green: 23.0 / 255.0, blue: 17.0 / 255.0, opacity: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .monochrome:
            Color(.sRGB, red: 35.0 / 255.0, green: 40.0 / 255.0, blue: 32.0 / 255.0, opacity: 1.0)
        case .tinted:
            LinearGradient(
                colors: [
                    Color(.sRGB, red: 234.0 / 255.0, green: 240.0 / 255.0, blue: 222.0 / 255.0, opacity: 1.0),
                    Color(.sRGB, red: 201.0 / 255.0, green: 214.0 / 255.0, blue: 168.0 / 255.0, opacity: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct NotebookReviewMark: View {
    let variant: NotebookVariant
    let tint: Color
    var evidenceTint: Color? = nil

    var body: some View {
        GeometryReader { geometry in
            if variant == .bandAndRibbon {
                let side = min(geometry.size.width, geometry.size.height)
                MnemoLogoMark(size: side, style: .filled, tint: tint)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                variantCanvas
            }
        }
        .accessibilityHidden(true)
    }

    private var variantCanvas: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let origin = CGPoint(x: (size.width - side) / 2.0, y: (size.height - side) / 2.0)
            let rect: (CGFloat, CGFloat, CGFloat, CGFloat) -> CGRect = { x, y, width, height in
                CGRect(
                    x: origin.x + side * x,
                    y: origin.y + side * y,
                    width: side * width,
                    height: side * height
                )
            }

            let cover = Path(
                roundedRect: rect(13.0 / 48.0, 8.0 / 48.0, 22.0 / 48.0, 32.0 / 48.0),
                cornerRadius: side * 4.5 / 48.0
            )
            context.stroke(
                cover,
                with: .color(tint),
                style: StrokeStyle(lineWidth: side * 2.4 / 48.0, lineCap: .round, lineJoin: .round)
            )

            if variant != .ribbonOnly {
                let band = Path(
                    roundedRect: rect(28.0 / 48.0, 8.0 / 48.0, 4.0 / 48.0, 32.0 / 48.0),
                    cornerRadius: side * 1.2 / 48.0
                )
                context.fill(band, with: .color(tint))
            }

            var ribbon = Path()
            ribbon.move(to: CGPoint(x: origin.x + side * 18.0 / 48.0, y: origin.y + side * 40.0 / 48.0))
            ribbon.addLine(to: CGPoint(x: origin.x + side * 18.0 / 48.0, y: origin.y + side * 45.0 / 48.0))
            ribbon.addLine(to: CGPoint(x: origin.x + side * 20.5 / 48.0, y: origin.y + side * 43.0 / 48.0))
            ribbon.addLine(to: CGPoint(x: origin.x + side * 23.0 / 48.0, y: origin.y + side * 45.0 / 48.0))
            ribbon.addLine(to: CGPoint(x: origin.x + side * 23.0 / 48.0, y: origin.y + side * 40.0 / 48.0))
            ribbon.closeSubpath()

            let ribbonTint = variant == .evidenceRibbon ? (evidenceTint ?? DS.Colours.sourceAccent) : tint
            context.fill(ribbon, with: .color(ribbonTint))
        }
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
