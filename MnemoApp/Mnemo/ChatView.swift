import SwiftUI
import SwiftData
import MnemoUI
import MnemoCore
import MnemoMemory

/// Primary chat interface: the main surface for recall queries.
struct ChatView: View {

    @State private var viewModel = ChatViewModel()
    @Environment(NavigationCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \MemoryRecord.createdAt, order: .reverse) private var records: [MemoryRecord]
    @State private var selectedSourceMemory: ChatSelectedMemory?

    private var activeRecords: [MemoryRecord] {
        records.filter { !$0.isArchived }
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ZStack {
                DS.Colours.backgroundGrouped.ignoresSafeArea()

                VStack(spacing: DS.Spacing.xs) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: DS.Spacing.md) {
                                if viewModel.messages.isEmpty && !viewModel.isProcessing {
                                    EmptyChatLanding(
                                        hasSavedMemories: !activeRecords.isEmpty,
                                        onText: {
                                            coordinator.present(.captureText)
                                        },
                                        onVoice: {
                                            coordinator.present(.captureVoice)
                                        },
                                        onCamera: {
                                            coordinator.present(.captureImage(.camera))
                                        },
                                        onPhoto: {
                                            coordinator.present(.captureImage(.photoLibrary))
                                        },
                                        onExample: { example in
                                            viewModel.inputText = example
                                        }
                                    )
                                }

                                ForEach(viewModel.messages) { message in
                                    MessageBubble(
                                        message: message,
                                        onSourceTap: { id in
                                            selectedSourceMemory = ChatSelectedMemory(id: id)
                                        }
                                    )
                                        .id(message.id)
                                }

                                if !viewModel.messages.isEmpty && activeRecords.isEmpty && !viewModel.isProcessing {
                                    EmptyMemoryRecoveryPanel(
                                        onText: {
                                            coordinator.present(.captureText)
                                        },
                                        onVoice: {
                                            coordinator.present(.captureVoice)
                                        },
                                        onCamera: {
                                            coordinator.present(.captureImage(.camera))
                                        },
                                        onPhoto: {
                                            coordinator.present(.captureImage(.photoLibrary))
                                        },
                                        onReset: {
                                            viewModel.resetConversation()
                                        }
                                    )
                                }

                                if viewModel.isProcessing {
                                    TypingIndicator()
                                }

                                Color.clear
                                    .frame(height: 1.0)
                                    .id(ChatScrollAnchor.bottom)
                            }
                            .padding(.horizontal, DS.Spacing.md)
                            .padding(.top, DS.Spacing.md)
                            .padding(.bottom, DS.Spacing.xl)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onChange(of: viewModel.messages.count) {
                            if viewModel.messages.last?.role == .assistant {
                                HapticManager.impact(.soft)
                            }
                            withAnimation(reduceMotion ? DS.Animation.fade : DS.Animation.standard) {
                                proxy.scrollTo(ChatScrollAnchor.bottom, anchor: .bottom)
                            }
                        }
                    }

                    ChatInputBar(
                        text: $viewModel.inputText,
                        isProcessing: viewModel.isProcessing,
                        showsCaptureShortcuts: !viewModel.messages.isEmpty,
                        placeholder: activeRecords.isEmpty && viewModel.messages.isEmpty ? "Ask after saving a memory..." : "Ask about a saved memory...",
                        onText: {
                            coordinator.present(.captureText)
                        },
                        onCamera: {
                            coordinator.present(.captureImage(.camera))
                        },
                        onPhoto: {
                            coordinator.present(.captureImage(.photoLibrary))
                        },
                        onSend: {
                            HapticManager.impact(.light)
                            Task { await viewModel.send(context: modelContext) }
                        },
                        onVoice: {
                            coordinator.present(.captureVoice)
                        }
                    )
                }
            }
            .navigationTitle("Mnemo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: DS.Spacing.sm) {
                        if !viewModel.messages.isEmpty {
                            Button {
                                if reduceMotion {
                                    viewModel.resetConversation()
                                } else {
                                    withAnimation(DS.Animation.standard) {
                                        viewModel.resetConversation()
                                    }
                                }
                            } label: {
                                Image(systemName: "house")
                                    .font(DS.Typography.headline)
                                    .foregroundStyle(DS.Colours.accent)
                                    .frame(width: 44.0, height: 44.0)
                            }
                            .accessibilityLabel("Home")
                            .accessibilityHint("Return to the memory landing screen")
                            .accessibilityIdentifier("chat.homeButton")
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
                        }

                        Button {
                            coordinator.present(.settings)
                        } label: {
                            Image(systemName: "gearshape")
                                .font(DS.Typography.headline)
                                .foregroundStyle(DS.Colours.accent)
                                .frame(width: 44.0, height: 44.0)
                        }
                        .accessibilityLabel("Settings")
                        .accessibilityIdentifier(AccessibilityID.Main.settings)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.messages.isEmpty {
                        Button {
                            coordinator.present(.captureText)
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(DS.Typography.headline)
                                .foregroundStyle(DS.Colours.accent)
                                .frame(width: 44.0, height: 44.0)
                        }
                        .accessibilityLabel("Write memory")
                        .accessibilityIdentifier(AccessibilityID.CaptureText.open)
                    }
                }
            }
            .sheet(item: $selectedSourceMemory) { selected in
                if let record = records.first(where: { $0.id == selected.id }) {
                    MemoryDetailView(
                        record: record,
                        onArchive: archiveSourceMemory,
                        onDeletePermanently: deleteSourceMemoryPermanently
                    )
                } else {
                    MissingSourceView()
                }
            }
        }
    }

    @MainActor
    private func archiveSourceMemory(id: UUID) async throws {
        try await MemoryCRUD.archiveAndUnindex(id: id, in: modelContext)
    }

    @MainActor
    private func deleteSourceMemoryPermanently(id: UUID) async throws {
        try await MemoryCRUD.deletePermanently(id: id, in: modelContext)
    }
}

private enum ChatScrollAnchor {
    static let bottom = "chat-bottom"
}

struct MessageBubble: View {

    let message: ChatViewModel.Message
    let onSourceTap: (UUID) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack(alignment: .bottom) {
            if isUser {
                Spacer(minLength: DS.Spacing.xxxl)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: DS.Spacing.xs) {
                Text(message.content)
                    .font(DS.Typography.body)
                    .foregroundStyle(isUser ? DS.ComponentTokens.PrimaryButton.foreground : DS.Colours.textPrimary)
                    .multilineTextAlignment(isUser ? .trailing : .leading)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.md)
                    .background(isUser ? DS.Colours.accent : DS.Colours.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
                    .shadow(
                        color: DS.Shadows.subtle.color,
                        radius: DS.Shadows.subtle.radius,
                        x: DS.Shadows.subtle.x,
                        y: DS.Shadows.subtle.y
                    )

                if !isUser && !message.citedMemoryIds.isEmpty {
                    CitationSection(
                        citations: message.citations,
                        fallbackCount: message.citedMemoryIds.count,
                        onSourceTap: onSourceTap
                    )
                }

                Text(message.timestamp.formatted(.dateTime.hour().minute()))
                    .font(DS.Typography.caption2)
                    .foregroundStyle(DS.Colours.textTertiary)
            }

            if !isUser {
                Spacer(minLength: DS.Spacing.xxxl)
            }
        }
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: isUser ? .trailing : .leading)))
        .accessibilityIdentifier(isUser ? AccessibilityID.Chat.messageUser : AccessibilityID.Chat.messageAssistant)
    }
}

private struct ChatSelectedMemory: Identifiable {
    let id: UUID
}

struct CitationSection: View {

    let citations: [ChatViewModel.Message.Citation]
    let fallbackCount: Int
    let onSourceTap: (UUID) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Label(title, systemImage: "bookmark.fill")
                .font(DS.Typography.caption1.weight(.semibold))
                .foregroundStyle(DS.Colours.sourceCardAccent)
                .accessibilityLabel(title)

            if citations.isEmpty {
                Text(fallbackCount == 1 ? "Source memory is saved locally." : "\(fallbackCount) source memories are saved locally.")
                    .font(DS.Typography.caption1)
                    .foregroundStyle(DS.Colours.textSecondary)
                    .padding(DS.Spacing.sm)
                    .background(DS.Colours.sourceCardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
            } else {
                ForEach(Array(citations.prefix(3).enumerated()), id: \.element.id) { index, citation in
                    let isPrimary = citation.id == citations.first?.id
                    Button {
                        onSourceTap(citation.id)
                    } label: {
                        ZStack(alignment: .trailing) {
                            if isPrimary {
                                MnemoThreadMotif(style: .source, lineWidth: 1.8)
                                    .frame(width: 92.0, height: 72.0)
                                    .padding(.trailing, DS.Spacing.xs)
                            }

                            HStack(alignment: .center, spacing: DS.Spacing.sm) {
                                Capsule()
                                    .fill(isPrimary ? DS.Colours.sourceCardAccent : DS.Colours.borderStrong)
                                    .frame(width: 3.0, height: 40.0)
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                                    Text(citation.source)
                                        .font(DS.Typography.caption2.weight(.semibold))
                                        .foregroundStyle(isPrimary ? DS.Colours.sourceCardAccent : DS.Colours.textTertiary)
                                        .accessibilityIdentifier(AccessibilityID.Chat.sourceType)
                                    Text("\"\(citation.summary)\"")
                                        .font(DS.Typography.caption1)
                                        .foregroundStyle(DS.Colours.textSecondary)
                                        .lineLimit(4)
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer(minLength: DS.Spacing.xs)

                                Image(systemName: "chevron.right")
                                    .font(DS.Typography.caption1)
                                    .foregroundStyle(DS.Colours.textTertiary)
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding(DS.ComponentTokens.SourceCard.padding)
                        .background(isPrimary ? DS.ComponentTokens.SourceCard.background : DS.Colours.surfaceElevated)
                        .overlay {
                            RoundedRectangle(cornerRadius: DS.ComponentTokens.SourceCard.cornerRadius)
                                .stroke(isPrimary ? DS.ComponentTokens.SourceCard.border : DS.Colours.memoryCardBorder, lineWidth: 1.0)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: DS.ComponentTokens.SourceCard.cornerRadius))
                    }
                    .buttonStyle(.mnemoPressable)
                    .accessibilityLabel(sourceAccessibilityLabel(for: citation, index: index, isPrimary: isPrimary))
                    .accessibilityValue(citation.summary)
                    .accessibilityHint("Open source memory details")
                    .accessibilityIdentifier(citation.id == citations.first?.id ? AccessibilityID.Chat.sourceCardPrimary : AccessibilityID.Chat.sourceCard)
                    .transition(DS.Animation.sourceRevealTransition(reduceMotion: reduceMotion))
                }

                if citations.count > 3 {
                    Text("\(citations.count - 3) more source\(citations.count - 3 == 1 ? "" : "s") not shown")
                        .font(DS.Typography.caption2)
                        .foregroundStyle(DS.Colours.textTertiary)
                        .padding(.leading, DS.Spacing.md)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(DS.Animation.sourceRevealTransition(reduceMotion: reduceMotion))
    }

    private var title: String {
        fallbackCount == 1 ? "Memory used" : "Sources"
    }

    private func sourceAccessibilityLabel(
        for citation: ChatViewModel.Message.Citation,
        index: Int,
        isPrimary: Bool
    ) -> String {
        let sourcePosition = isPrimary ? "Primary source" : "Source \(index + 1) of \(min(citations.count, 3))"
        return "\(sourcePosition). \(citation.source) source memory"
    }
}

struct MissingSourceView: View {

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.md) {
                Image(systemName: "exclamationmark.magnifyingglass")
                    .font(DS.Typography.largeTitle)
                    .foregroundStyle(DS.Colours.textTertiary)
                    .accessibilityHidden(true)

                Text("Memory not found")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colours.textPrimary)

                Text("This source may have been deleted.")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textSecondary)
            }
            .padding(DS.Spacing.xl)
            .navigationTitle("Source")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TypingIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animating = false

    var body: some View {
        HStack {
            HStack(spacing: DS.Spacing.xs) {
                if reduceMotion {
                    dot
                } else {
                    ForEach(0..<3, id: \.self) { index in
                        dot
                            .offset(y: animating ? -6.0 : 0.0)
                            .animation(
                                Animation.easeInOut(duration: 0.45)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.15),
                                value: animating
                            )
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .background(DS.Colours.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
                .shadow(
                    color: DS.Shadows.subtle.color,
                    radius: DS.Shadows.subtle.radius,
                    x: DS.Shadows.subtle.x,
                    y: DS.Shadows.subtle.y
                )
            Spacer(minLength: DS.Spacing.xxxl)
        }
        .accessibilityLabel("Looking through saved memories")
        .onAppear {
            animating = true
        }
    }

    private var dot: some View {
        Circle()
            .fill(DS.Colours.textTertiary)
            .frame(width: 8.0, height: 8.0)
    }
}

struct EmptyChatLanding: View {

    let hasSavedMemories: Bool
    let onText: () -> Void
    let onVoice: () -> Void
    let onCamera: () -> Void
    let onPhoto: () -> Void
    let onExample: (String) -> Void

    private let compactColumns = [
        GridItem(.flexible(), spacing: DS.Spacing.sm),
        GridItem(.flexible(), spacing: DS.Spacing.sm),
        GridItem(.flexible(), spacing: DS.Spacing.sm),
    ]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var secondaryColumns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible(), spacing: DS.Spacing.sm)]
            : compactColumns
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                HStack(alignment: .top, spacing: DS.Spacing.md) {
                    ZStack {
                        MnemoThreadMotif(style: .watermark, lineWidth: 1.5)
                            .frame(width: 64.0, height: 52.0)
                        MnemoLogoMark(size: 42.0, style: .subtle)
                    }
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        Text("What should Mnemo remember?")
                            .font(DS.Typography.title2)
                            .foregroundStyle(DS.Colours.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)

                        Text("Save a detail, decision or reminder. Ask for it later and see the source.")
                            .font(DS.Typography.subheadline)
                            .foregroundStyle(DS.Colours.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier(AccessibilityID.Chat.landing)
                    }
                }

                Label("Private on this iPhone", systemImage: "lock.shield.fill")
                    .font(DS.Typography.caption1.weight(.semibold))
                    .foregroundStyle(privateBadgeForeground)
                    .padding(.horizontal, DS.Spacing.sm)
                    .padding(.vertical, DS.Spacing.xs)
                    .background {
                        Capsule()
                            .fill(DS.Colours.privateBadgeSurface)
                        if #available(iOS 26.0, *) {
                            Capsule()
                                .glassEffect(.regular.tint(DS.Colours.accent).interactive(), in: .capsule)
                        }
                    }
                    .clipShape(Capsule())
            }
            .padding(.horizontal, DS.Spacing.xs)
            .transition(DS.Animation.cardAppearTransition(reduceMotion: reduceMotion))

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                LandingActionButton(
                    title: "Write memory",
                    subtitle: "Type a detail, decision or reminder",
                    icon: "square.and.pencil",
                    tint: DS.Colours.accent,
                    prominence: .primary,
                    accessibilityIdentifier: AccessibilityID.CaptureText.open,
                    action: onText
                )

                LazyVGrid(columns: secondaryColumns, spacing: DS.Spacing.sm) {
                    LandingActionButton(
                        title: "Voice",
                        subtitle: "",
                        icon: "mic.fill",
                        tint: DS.Colours.accent,
                        prominence: .compact,
                        accessibilityIdentifier: "capture.voice.open",
                        action: onVoice
                    )
                    LandingActionButton(
                        title: "Camera",
                        subtitle: "",
                        icon: "camera.fill",
                        tint: DS.Colours.accent,
                        prominence: .compact,
                        accessibilityIdentifier: "capture.camera.open",
                        action: onCamera
                    )
                    LandingActionButton(
                        title: "Photo",
                        subtitle: "",
                        icon: "photo.on.rectangle",
                        tint: DS.Colours.accent,
                        prominence: .compact,
                        accessibilityIdentifier: "capture.photo.open",
                        action: onPhoto
                    )
                }
            }

            if hasSavedMemories {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("Ask Mnemo")
                        .font(DS.Typography.headline)
                        .foregroundStyle(DS.Colours.textPrimary)

                    VStack(spacing: DS.Spacing.xs) {
                        RecallExampleButton(
                            text: "What did I save most recently?",
                            action: { onExample("What did I save most recently?") }
                        )
                        RecallExampleButton(
                            text: "What decision did I save?",
                            action: { onExample("What decision did I save?") }
                        )
                        RecallExampleButton(
                            text: "Where did I put it?",
                            action: { onExample("Where did I put it?") }
                        )
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Label("Save your first memory, then ask naturally.", systemImage: "arrow.turn.down.right")
                        .font(DS.Typography.subheadline)
                        .foregroundStyle(DS.Colours.textSecondary)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.xs)
        .padding(.top, DS.Spacing.md)
        .padding(.bottom, DS.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var privateBadgeForeground: Color {
        if #available(iOS 26.0, *) {
            return DS.Colours.textOnAccent
        }

        return DS.Colours.privateBadgeText
    }
}

struct EmptyMemoryRecoveryPanel: View {
    let onText: () -> Void
    let onVoice: () -> Void
    let onCamera: () -> Void
    let onPhoto: () -> Void
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text("Start by saving one memory")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colours.textPrimary)

                Text("Once Mnemo has something saved, ask for it here.")
                    .font(DS.Typography.footnote)
                    .foregroundStyle(DS.Colours.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: DS.Spacing.sm) {
                CompactCaptureButton(title: "Write", icon: "square.and.pencil", action: onText)
                CompactCaptureButton(title: "Voice", icon: "mic.fill", action: onVoice)
                CompactCaptureButton(title: "Camera", icon: "camera.fill", action: onCamera)
                CompactCaptureButton(title: "Photo", icon: "photo", action: onPhoto)
            }

            Button(action: onReset) {
                Label("Back to start", systemImage: "house")
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(DS.Colours.accent)
            }
            .buttonStyle(.mnemoPressable)
        }
        .padding(DS.Spacing.md)
        .background(DS.Colours.memoryCardSurface)
        .overlay {
            RoundedRectangle(cornerRadius: DS.CornerRadius.large)
                .stroke(DS.Colours.memoryCardBorder, lineWidth: 1.0)
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
        .shadow(
            color: DS.Shadows.subtle.color,
            radius: DS.Shadows.subtle.radius,
            x: DS.Shadows.subtle.x,
            y: DS.Shadows.subtle.y
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CompactCaptureButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DS.Spacing.xs) {
                Image(systemName: icon)
                    .font(DS.Typography.headline)
                Text(title)
                    .font(DS.Typography.caption1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(DS.Colours.accent)
            .frame(maxWidth: .infinity, minHeight: 52.0)
            .background(DS.Colours.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
        }
        .buttonStyle(.mnemoPressable)
    }
}

struct LandingActionButton: View {
    enum Prominence {
        case primary
        case secondary
        case compact
    }

    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let prominence: Prominence
    let accessibilityIdentifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if prominence == .compact {
                VStack(spacing: DS.Spacing.xs) {
                    Image(systemName: icon)
                        .font(DS.Typography.headline)
                        .foregroundStyle(iconColor)
                        .accessibilityHidden(true)

                    Text(title)
                        .font(DS.Typography.caption1)
                        .foregroundStyle(titleColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .frame(maxWidth: .infinity, minHeight: 52.0)
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.vertical, DS.Spacing.xs)
                .background(backgroundColor)
                .overlay {
                    RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                        .stroke(DS.Colours.borderSubtle, lineWidth: 1.0)
                }
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
            } else {
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: icon)
                        .font(DS.Typography.title3)
                        .foregroundStyle(iconColor)
                        .frame(width: DS.Spacing.xl, alignment: .leading)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text(title)
                            .font(DS.Typography.headline)
                            .foregroundStyle(titleColor)
                        Text(subtitle)
                            .font(DS.Typography.caption1)
                            .foregroundStyle(subtitleColor)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(DS.Typography.caption1.weight(.semibold))
                        .foregroundStyle(iconColor.opacity(0.86))
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, minHeight: prominence == .primary ? 60.0 : 56.0, alignment: .leading)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
                .shadow(
                    color: prominence == .primary ? DS.Shadows.subtle.color : Color.clear,
                    radius: prominence == .primary ? DS.Shadows.subtle.radius : 0.0,
                    x: DS.Shadows.subtle.x,
                    y: DS.Shadows.subtle.y
                )
            }
        }
        .buttonStyle(.mnemoPressable)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle.isEmpty ? "Save a \(title.lowercased()) memory" : subtitle)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var backgroundColor: Color {
        prominence == .primary ? DS.Colours.accent : DS.Colours.surfaceElevated
    }

    private var iconColor: Color {
        prominence == .primary ? DS.Colours.textOnAccent : tint
    }

    private var titleColor: Color {
        prominence == .primary ? DS.Colours.textOnAccent : DS.Colours.textPrimary
    }

    private var subtitleColor: Color {
        prominence == .primary ? DS.Colours.textOnAccent.opacity(0.88) : DS.Colours.textSecondary
    }
}

struct RecallExampleButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(DS.Colours.accent)
                Text(text)
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(DS.Colours.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: DS.Spacing.sm)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .background(DS.Colours.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
        }
        .buttonStyle(.mnemoPressable)
    }
}

struct ChatInputBar: View {

    @Binding var text: String
    let isProcessing: Bool
    let showsCaptureShortcuts: Bool
    let placeholder: String
    let onText: () -> Void
    let onCamera: () -> Void
    let onPhoto: () -> Void
    let onSend: () -> Void
    let onVoice: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sendIsActive = false

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isProcessing
    }

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            if showsCaptureShortcuts {
                Menu {
                    Button(action: onText) {
                        Label("Write Memory", systemImage: "square.and.pencil")
                    }

                    if dynamicTypeSize.isAccessibilitySize {
                        Button(action: onVoice) {
                            Label("Record Voice", systemImage: "mic.fill")
                        }
                    }

                    Button(action: onCamera) {
                        Label("Take Photo", systemImage: "camera")
                    }

                    Button(action: onPhoto) {
                        Label("Choose Photo", systemImage: "photo")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24.0, weight: .semibold))
                        .foregroundStyle(DS.Colours.accent)
                        .frame(width: 44.0, height: 44.0)
                }
                .buttonStyle(.mnemoPressable)
                .accessibilityLabel("Add memory")
                .accessibilityHint("Choose how to save a memory")
                .accessibilityIdentifier(AccessibilityID.Main.capture)
            }

            if showsCaptureShortcuts && !dynamicTypeSize.isAccessibilitySize {
                Button(action: onVoice) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 20.0, weight: .semibold))
                        .foregroundStyle(DS.Colours.accent)
                        .frame(width: 36.0, height: 36.0)
                        .background(DS.Colours.accentSoft)
                        .clipShape(Circle())
                        .frame(width: 44.0, height: 44.0)
                }
                .buttonStyle(.mnemoPressable)
                .accessibilityLabel("Record voice memory")
                .accessibilityHint("Open voice capture")
                .accessibilityIdentifier("capture.voice.open")
            }

            TextField(placeholder, text: $text, axis: .vertical)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textPrimary)
                .lineLimit(1...4)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
                .background(DS.Colours.surfaceSecondary)
                .overlay {
                    RoundedRectangle(cornerRadius: DS.CornerRadius.large)
                        .stroke(DS.Colours.borderSubtle, lineWidth: 0.8)
                }
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
                .onSubmit {
                    onSend()
                }
                .submitLabel(.send)
                .accessibilityIdentifier(AccessibilityID.Chat.input)

            Button(action: onSend) {
                Image(systemName: isProcessing ? "ellipsis" : "arrow.up.circle.fill")
                    .font(.system(size: 32.0, weight: .semibold))
                    .foregroundStyle(sendIsActive ? DS.Colours.accent : DS.Colours.textTertiary)
                    .frame(width: 44.0, height: 44.0)
                    .contentTransition(.symbolEffect(.replace))
            }
            .disabled(!canSend)
            .buttonStyle(.mnemoPressable)
            .accessibilityLabel("Send")
            .accessibilityHint("Ask Mnemo to recall a saved memory")
            .accessibilityIdentifier(AccessibilityID.Chat.send)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(DS.Colours.borderSubtle)
                .frame(height: DS.Spacing.xs / DS.Spacing.xs)
        }
        .onAppear {
            sendIsActive = canSend
        }
        .onChange(of: canSend) { _, newValue in
            withAnimation(reduceMotion ? DS.Animation.fade : DS.Animation.quick) {
                sendIsActive = newValue
            }
        }
    }
}
