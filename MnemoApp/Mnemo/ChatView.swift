import SwiftUI
import SwiftData
#if os(iOS)
import UIKit
#endif
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
                DS.Colours.canvas.ignoresSafeArea()

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
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 12.0)
                                .onChanged { _ in
                                    dismissKeyboard()
                                }
                        )
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
                    Button {
                        coordinator.present(.settings)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityIdentifier(AccessibilityID.Main.settings)
                }

                ToolbarItem(placement: .topBarTrailing) {
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
                            Image(systemName: "square.and.pencil")
                        }
                        .accessibilityLabel("New conversation")
                        .accessibilityHint("Clear this conversation and return to Recall")
                        .accessibilityIdentifier(AccessibilityID.Chat.newConversation)
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
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

    private func dismissKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        #endif
    }
}

private enum ChatScrollAnchor {
    static let bottom = "chat-bottom"
}

struct MessageBubble: View {

    let message: ChatViewModel.Message
    let onSourceTap: (UUID) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack(alignment: .top) {
            if isUser {
                Spacer(minLength: DS.Spacing.xxl)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                if !isUser {
                    Label("Mnemo", systemImage: "bookmark")
                        .font(DS.Typography.caption1.weight(.semibold))
                        .foregroundStyle(DS.Colours.sourceAccent)
                        .accessibilityHidden(true)
                }

                Text(message.content)
                    .font(DS.Typography.body)
                    .foregroundStyle(isUser ? DS.Colours.textOnAccent : DS.Colours.textPrimary)
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.sm + DS.Spacing.xs)
                    .background(isUser ? DS.Colours.controlAccent : DS.Colours.contentSurfaceElevated)
                    .overlay {
                        if !isUser || colorSchemeContrast == .increased {
                            RoundedRectangle(cornerRadius: bubbleCornerRadius)
                                .stroke(bubbleBorder, lineWidth: colorSchemeContrast == .increased ? 1.5 : 1.0)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: bubbleCornerRadius))

                if !isUser && !message.citedMemoryIds.isEmpty {
                    CitationSection(
                        citations: message.citations,
                        citedMemoryIDs: message.citedMemoryIds,
                        onSourceTap: onSourceTap
                    )
                }
            }

            if !isUser {
                Spacer(minLength: DS.Spacing.xl)
            }
        }
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: isUser ? .trailing : .leading)))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(isUser ? "You" : "Mnemo answer")
        .accessibilityIdentifier(isUser ? AccessibilityID.Chat.messageUser : AccessibilityID.Chat.messageAssistant)
    }

    private var bubbleCornerRadius: CGFloat {
        isUser ? DS.CornerRadius.large : DS.CornerRadius.medium
    }

    private var bubbleBorder: Color {
        isUser ? DS.Colours.textOnAccent.opacity(0.72) : (colorSchemeContrast == .increased ? DS.Colours.borderStrong : DS.Colours.separator)
    }
}

private struct ChatSelectedMemory: Identifiable {
    let id: UUID
}

private struct CitationSourceItem: Identifiable {
    let id: UUID
    let citation: ChatViewModel.Message.Citation?
}

struct CitationSection: View {

    let citations: [ChatViewModel.Message.Citation]
    let citedMemoryIDs: [UUID]
    let onSourceTap: (UUID) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @State private var showsAllSources = false

    private var sourceCount: Int {
        sourceItems.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Label(title, systemImage: "bookmark.fill")
                .font(DS.Typography.caption1.weight(.semibold))
                .foregroundStyle(DS.Colours.sourceAccent)
                .accessibilityLabel(title)

            ForEach(Array(visibleSourceItems.enumerated()), id: \.element.id) { index, item in
                if let citation = item.citation {
                    SourceCitationButton(
                        citation: citation,
                        index: index,
                        count: sourceCount,
                        isPrimary: index == 0,
                        increasedContrast: colorSchemeContrast == .increased,
                        onSourceTap: onSourceTap
                    )
                    .transition(DS.Animation.sourceRevealTransition(reduceMotion: reduceMotion))
                } else {
                    SourceFallbackButton(
                        id: item.id,
                        index: index,
                        count: sourceCount,
                        onSourceTap: onSourceTap
                    )
                }
            }

            if sourceCount > 2 {
                Button {
                    withAnimation(reduceMotion ? DS.Animation.fade : DS.Animation.standard) {
                        showsAllSources.toggle()
                    }
                } label: {
                    Label(
                        showsAllSources ? "Show fewer sources" : "Show \(sourceCount - 2) more source\(sourceCount - 2 == 1 ? "" : "s")",
                        systemImage: showsAllSources ? "chevron.up" : "chevron.down"
                    )
                    .font(DS.Typography.caption1.weight(.semibold))
                    .foregroundStyle(DS.Colours.sourceAccent)
                    .frame(minHeight: 44.0)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityID.Chat.sourceDisclosure)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .transition(DS.Animation.sourceRevealTransition(reduceMotion: reduceMotion))
    }

    private var title: String {
        sourceCount == 1 ? "Memory used" : "\(sourceCount) memories used"
    }

    private var sourceItems: [CitationSourceItem] {
        var items = citedMemoryIDs.map { id in
            CitationSourceItem(id: id, citation: citations.first(where: { $0.id == id }))
        }
        let citedIDs = Set(citedMemoryIDs)
        items.append(contentsOf: citations.compactMap { citation in
            guard !citedIDs.contains(citation.id) else { return nil }
            return CitationSourceItem(id: citation.id, citation: citation)
        })
        return items
    }

    private var visibleSourceItems: ArraySlice<CitationSourceItem> {
        sourceItems.prefix(showsAllSources ? sourceItems.count : 2)
    }
}

private struct SourceCitationButton: View {
    let citation: ChatViewModel.Message.Citation
    let index: Int
    let count: Int
    let isPrimary: Bool
    let increasedContrast: Bool
    let onSourceTap: (UUID) -> Void

    var body: some View {
        Button {
            onSourceTap(citation.id)
        } label: {
            HStack(alignment: .top, spacing: DS.Spacing.sm) {
                Image(systemName: sourceIcon)
                    .font(DS.Typography.subheadline.weight(.semibold))
                    .foregroundStyle(DS.Colours.sourceAccent)
                    .frame(width: 24.0, height: 24.0)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    HStack(spacing: DS.Spacing.xs) {
                        Text(citation.source)
                            .font(DS.Typography.caption1.weight(.semibold))
                            .foregroundStyle(DS.Colours.sourceAccent)
                            .accessibilityIdentifier(AccessibilityID.Chat.sourceType)

                        if isPrimary {
                            Text("Primary")
                                .font(DS.Typography.caption2.weight(.semibold))
                                .foregroundStyle(DS.Colours.textPrimary)
                                .padding(.horizontal, DS.Spacing.sm)
                                .padding(.vertical, DS.Spacing.xs)
                                .background(DS.Colours.contentSurfaceElevated)
                                .clipShape(Capsule())
                        }
                    }

                    Text(citation.summary)
                        .font(DS.Typography.footnote)
                        .foregroundStyle(DS.Colours.textSecondary)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: DS.Spacing.xs)

                Image(systemName: "chevron.right")
                    .font(DS.Typography.caption1.weight(.semibold))
                    .foregroundStyle(DS.Colours.textSecondary)
                    .frame(minHeight: 24.0)
                    .accessibilityHidden(true)
            }
            .padding(DS.ComponentTokens.SourceCard.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isPrimary ? DS.ComponentTokens.SourceCard.background : DS.Colours.contentSurfaceElevated)
            .overlay {
                RoundedRectangle(cornerRadius: DS.ComponentTokens.SourceCard.cornerRadius)
                    .stroke(
                        isPrimary || increasedContrast ? DS.ComponentTokens.SourceCard.border : DS.Colours.memoryCardBorder,
                        lineWidth: increasedContrast ? 1.5 : 1.0
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: DS.ComponentTokens.SourceCard.cornerRadius))
        }
        .buttonStyle(.mnemoPressable)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(citation.summary)
        .accessibilityHint("Open source memory details")
        .accessibilityIdentifier(isPrimary ? AccessibilityID.Chat.sourceCardPrimary : AccessibilityID.Chat.sourceCard)
    }

    private var accessibilityLabel: String {
        let position = isPrimary ? "Primary source" : "Source \(index + 1) of \(count)"
        return "\(position), \(citation.source) memory"
    }

    private var sourceIcon: String {
        let source = citation.source.lowercased()
        if source.contains("voice") || source.contains("audio") {
            return "waveform"
        }
        if source.contains("photo") || source.contains("image") || source.contains("camera") {
            return "photo"
        }
        return "doc.text"
    }
}

private struct SourceFallbackButton: View {
    let id: UUID
    let index: Int
    let count: Int
    let onSourceTap: (UUID) -> Void
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    var body: some View {
        Button {
            onSourceTap(id)
        } label: {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "bookmark")
                    .foregroundStyle(DS.Colours.sourceAccent)
                    .accessibilityHidden(true)

                Text(count == 1 ? "Open source memory" : "Open source memory \(index + 1)")
                    .font(DS.Typography.footnote.weight(.semibold))
                    .foregroundStyle(DS.Colours.textPrimary)

                Spacer(minLength: DS.Spacing.xs)

                Image(systemName: "chevron.right")
                    .font(DS.Typography.caption1.weight(.semibold))
                    .foregroundStyle(DS.Colours.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(DS.ComponentTokens.SourceCard.padding)
            .frame(maxWidth: .infinity, minHeight: 44.0, alignment: .leading)
            .background(DS.Colours.sourceSurface)
            .overlay {
                RoundedRectangle(cornerRadius: DS.ComponentTokens.SourceCard.cornerRadius)
                    .stroke(DS.Colours.sourceBorder, lineWidth: colorSchemeContrast == .increased ? 1.5 : 1.0)
            }
            .clipShape(RoundedRectangle(cornerRadius: DS.ComponentTokens.SourceCard.cornerRadius))
        }
        .buttonStyle(.mnemoPressable)
        .accessibilityLabel(count == 1 ? "Source memory" : "Source \(index + 1) of \(count)")
        .accessibilityHint("Open source memory details")
        .accessibilityIdentifier(index == 0 ? AccessibilityID.Chat.sourceCardPrimary : AccessibilityID.Chat.sourceCard)
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

    var body: some View {
        HStack {
            HStack(spacing: DS.Spacing.sm) {
                if reduceMotion {
                    Image(systemName: "bookmark")
                        .foregroundStyle(DS.Colours.sourceAccent)
                        .accessibilityHidden(true)
                } else {
                    ProgressView()
                        .controlSize(.small)
                        .tint(DS.Colours.sourceAccent)
                        .accessibilityHidden(true)
                }

                Text("Looking through your memories")
                    .font(DS.Typography.footnote)
                    .foregroundStyle(DS.Colours.textSecondary)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm + DS.Spacing.xs)
            .background(DS.Colours.contentSurfaceElevated)
            .overlay {
                RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                    .stroke(DS.Colours.separator, lineWidth: 1.0)
            }
            .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
            Spacer(minLength: DS.Spacing.xl)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Looking through your memories")
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
                Label("New conversation", systemImage: "square.and.pencil")
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(DS.Colours.accent)
            }
            .buttonStyle(.mnemoPressable)
            .accessibilityHint("Clear this conversation and return to Recall")
            .accessibilityIdentifier(AccessibilityID.Chat.newConversation)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
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

                    Button(action: onVoice) {
                        Label("Record Voice", systemImage: "mic.fill")
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
                        .foregroundStyle(DS.Colours.controlAccent)
                        .frame(width: 44.0, height: 44.0)
                }
                .buttonStyle(.mnemoPressable)
                .accessibilityLabel("Add memory")
                .accessibilityHint("Choose how to save a memory")
                .accessibilityIdentifier(AccessibilityID.Chat.captureMenu)
            }

            TextField(placeholder, text: $text, axis: .vertical)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textPrimary)
                .lineLimit(1...4)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
                .background(DS.Colours.controlFallback)
                .overlay {
                    RoundedRectangle(cornerRadius: DS.CornerRadius.large)
                        .stroke(
                            colorSchemeContrast == .increased ? DS.Colours.borderStrong : DS.Colours.separator,
                            lineWidth: colorSchemeContrast == .increased ? 1.5 : 1.0
                        )
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
                    .foregroundStyle(sendIsActive ? DS.Colours.controlAccent : DS.Colours.textTertiary)
                    .frame(width: 44.0, height: 44.0)
            }
            .disabled(!canSend)
            .buttonStyle(.mnemoPressable)
            .accessibilityLabel("Send")
            .accessibilityValue(canSend ? "Available" : "Unavailable")
            .accessibilityHint("Ask Mnemo to recall a saved memory")
            .accessibilityIdentifier(AccessibilityID.Chat.send)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
        .background {
            if reduceTransparency {
                DS.Colours.contentSurfaceElevated
            } else {
                Rectangle().fill(.regularMaterial)
            }
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(colorSchemeContrast == .increased ? DS.Colours.borderStrong : DS.Colours.separator)
                .frame(height: colorSchemeContrast == .increased ? 1.5 : 1.0)
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
