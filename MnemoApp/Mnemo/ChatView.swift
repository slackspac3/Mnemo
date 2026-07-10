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
    @State private var sendTask: Task<Void, Never>?
    @FocusState private var inputIsFocused: Bool

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
                        GeometryReader { viewport in
                            ScrollView {
                                LazyVStack(spacing: DS.Spacing.md) {
                                    if viewModel.messages.isEmpty && !viewModel.isProcessing {
                                        EmptyChatLanding(
                                            hasSavedMemories: !activeRecords.isEmpty,
                                            minimumHeight: max(
                                                viewport.size.height - DS.Spacing.md - DS.Spacing.xl,
                                                0
                                            ),
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
                                                HapticManager.impact(.light)
                                                viewModel.inputText = example
                                                inputIsFocused = true
                                                announceForAccessibility("Question added to Recall field")
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
                                                resetConversation()
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
                                if reduceMotion {
                                    proxy.scrollTo(ChatScrollAnchor.bottom, anchor: .bottom)
                                } else {
                                    withAnimation(DS.Animation.standard) {
                                        proxy.scrollTo(ChatScrollAnchor.bottom, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }

                    ChatInputBar(
                        text: $viewModel.inputText,
                        focus: $inputIsFocused,
                        isProcessing: viewModel.isProcessing,
                        showsCaptureShortcuts: !viewModel.messages.isEmpty,
                        placeholder: activeRecords.isEmpty && viewModel.messages.isEmpty ? "Ask after saving a memory..." : "Ask about a saved memory...",
                        inputAccessibilityHint: activeRecords.isEmpty
                            ? "Save a memory before asking Mnemo"
                            : "Ask Mnemo about a saved memory",
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
                            sendTask?.cancel()
                            sendTask = Task { @MainActor in
                                await viewModel.send(context: modelContext)
                                if !Task.isCancelled {
                                    sendTask = nil
                                }
                            }
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
                            .foregroundStyle(DS.Colours.accent)
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityIdentifier(AccessibilityID.Main.settings)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.messages.isEmpty {
                        Button {
                            if reduceMotion {
                                resetConversation()
                            } else {
                                withAnimation(DS.Animation.standard) {
                                    resetConversation()
                                }
                            }
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .foregroundStyle(DS.Colours.accent)
                        }
                        .accessibilityLabel("New conversation")
                        .accessibilityHint(
                            viewModel.isProcessing
                                ? "Clear this conversation and ignore the pending answer"
                                : "Clear this conversation and return to Recall"
                        )
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
            .onChange(of: viewModel.isProcessing) { _, isProcessing in
                guard isProcessing else { return }
                announceForAccessibility("Looking through your memories")
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                guard let answer = viewModel.messages.last,
                      answer.role == .assistant
                else { return }
                announceForAccessibility("Mnemo answered. \(answer.content)")
            }
        }
    }

    @MainActor
    private func resetConversation() {
        sendTask?.cancel()
        sendTask = nil
        viewModel.resetConversation()
    }

    @MainActor
    private func archiveSourceMemory(id: UUID) async throws {
        try await MemoryCRUD.archiveAndUnindex(id: id, in: modelContext)
    }

    @MainActor
    private func deleteSourceMemoryPermanently(id: UUID) async throws {
        try await MemoryCRUD.deletePermanently(id: id, in: modelContext)
    }

    private func announceForAccessibility(_ message: String) {
        #if os(iOS)
        UIAccessibility.post(notification: .announcement, argument: message)
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
                        .foregroundStyle(
                            message.citedMemoryIds.isEmpty
                                ? DS.Colours.accent
                                : DS.Colours.sourceAccent
                        )
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
                        .foregroundStyle(DS.Colours.textPrimary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 4)
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
                        increasedContrast
                            ? DS.Colours.sourceAccent
                            : (isPrimary ? DS.ComponentTokens.SourceCard.border : DS.Colours.memoryCardBorder),
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
                    .stroke(
                        colorSchemeContrast == .increased ? DS.Colours.sourceAccent : DS.Colours.sourceBorder,
                        lineWidth: colorSchemeContrast == .increased ? 1.5 : 1.0
                    )
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

    @Environment(\.dismiss) private var dismiss

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
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityHint("Close source details")
                }
            }
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
                        .foregroundStyle(DS.Colours.accent)
                        .accessibilityHidden(true)
                } else {
                    ProgressView()
                        .controlSize(.small)
                        .tint(DS.Colours.accent)
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
    let minimumHeight: CGFloat
    let onText: () -> Void
    let onVoice: () -> Void
    let onCamera: () -> Void
    let onPhoto: () -> Void
    let onExample: (String) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AccessibilityFocusState private var headingIsFocused: Bool
    @State private var requestedInitialFocus = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            landingHeader

            Spacer(minLength: hasSavedMemories ? DS.Spacing.lg : DS.Spacing.xl)

            if hasSavedMemories {
                recallFirstContent
            } else {
                firstMemoryContent
            }
        }
        .frame(
            maxWidth: DS.ComponentTokens.EmptyState.maxWidth,
            minHeight: minimumHeight,
            alignment: .topLeading
        )
        .frame(maxWidth: .infinity, alignment: .center)
        .transition(DS.Animation.cardAppearTransition(reduceMotion: reduceMotion))
        .task {
            guard !requestedInitialFocus else { return }
            requestedInitialFocus = true

            await Task.yield()
            guard !Task.isCancelled else { return }
            headingIsFocused = true
        }
    }

    private var landingHeader: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    brandMark
                    heading
                }
            } else {
                HStack(alignment: .center, spacing: DS.Spacing.md) {
                    brandMark
                    heading
                }
            }

            Text(
                hasSavedMemories
                    ? "Ask naturally. Mnemo answers from what you saved and shows the source."
                    : "Save it privately. Ask naturally later, then open the source."
            )
                .font(DS.Typography.subheadline)
                .foregroundStyle(DS.Colours.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(AccessibilityID.Chat.landing)

            Label("Private on this iPhone", systemImage: "lock.fill")
                .font(DS.Typography.caption1.weight(.semibold))
                .foregroundStyle(DS.Colours.privateBadgeText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var brandMark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DS.CornerRadius.medium, style: .continuous)
                .fill(DS.Colours.accentSoft)

            MnemoLogoMark(size: 36.0, style: .filled)
        }
        .frame(width: 52.0, height: 52.0)
        .accessibilityHidden(true)
    }

    private var heading: some View {
        Text(hasSavedMemories ? "What would you like to recall?" : "What should Mnemo remember?")
            .font(DS.Typography.title2)
            .foregroundStyle(DS.Colours.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
            .accessibilityFocused($headingIsFocused)
    }

    private var firstMemoryContent: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            LandingPrimaryActionButton(
                title: "Write memory",
                subtitle: "Type a detail, decision, or reminder",
                icon: "square.and.pencil",
                accessibilityHint: "Open text capture",
                accessibilityIdentifier: AccessibilityID.CaptureText.open,
                action: onText
            )

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Text("Capture another way")
                    .font(DS.Typography.caption1.weight(.semibold))
                    .foregroundStyle(DS.Colours.textSecondary)
                    .accessibilityAddTraits(.isHeader)

                LandingCaptureGroup(
                    includesText: false,
                    onText: onText,
                    onVoice: onVoice,
                    onCamera: onCamera,
                    onPhoto: onPhoto
                )
            }
        }
    }

    private var recallFirstContent: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Text("Try asking")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colours.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 0) {
                    RecallExampleButton(
                        text: "What did I save most recently?",
                        action: { onExample("What did I save most recently?") }
                    )
                    Divider().padding(.leading, DS.Spacing.md)
                    RecallExampleButton(
                        text: "What decision did I save?",
                        action: { onExample("What decision did I save?") }
                    )
                    Divider().padding(.leading, DS.Spacing.md)
                    RecallExampleButton(
                        text: "Where did I put it?",
                        action: { onExample("Where did I put it?") }
                    )
                }
                .mnemoSurface(.contentFallback, cornerRadius: DS.CornerRadius.medium)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Text("Add a memory")
                    .font(DS.Typography.caption1.weight(.semibold))
                    .foregroundStyle(DS.Colours.textSecondary)
                    .accessibilityAddTraits(.isHeader)

                LandingCaptureGroup(
                    includesText: true,
                    onText: onText,
                    onVoice: onVoice,
                    onCamera: onCamera,
                    onPhoto: onPhoto
                )
            }
        }
    }

}

struct EmptyMemoryRecoveryPanel: View {
    let onText: () -> Void
    let onVoice: () -> Void
    let onCamera: () -> Void
    let onPhoto: () -> Void
    let onReset: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var captureColumns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 4
        return Array(
            repeating: GridItem(.flexible(), spacing: DS.Spacing.sm),
            count: count
        )
    }

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

            LazyVGrid(columns: captureColumns, spacing: DS.Spacing.sm) {
                CompactCaptureButton(title: "Write", icon: "square.and.pencil", action: onText)
                CompactCaptureButton(title: "Voice", icon: "mic.fill", action: onVoice)
                CompactCaptureButton(title: "Camera", icon: "camera.fill", action: onCamera)
                CompactCaptureButton(title: "Photo", icon: "photo", action: onPhoto)
            }

            Button(action: onReset) {
                Label("New conversation", systemImage: "square.and.pencil")
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(DS.Colours.accent)
                    .frame(minHeight: 44.0)
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CompactCaptureButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: action) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    HStack(spacing: DS.Spacing.sm) {
                        Image(systemName: icon)
                            .font(DS.Typography.headline)
                            .frame(width: DS.Spacing.xl)
                        Text(title)
                            .font(DS.Typography.body.weight(.semibold))
                        Spacer(minLength: 0)
                    }
                } else {
                    VStack(spacing: DS.Spacing.xs) {
                        Image(systemName: icon)
                            .font(DS.Typography.headline)
                        Text(title)
                            .font(DS.Typography.caption1)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
            .foregroundStyle(DS.Colours.accent)
            .frame(maxWidth: .infinity, minHeight: 52.0)
            .padding(.horizontal, dynamicTypeSize.isAccessibilitySize ? DS.Spacing.md : 0)
            .background(DS.Colours.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
        }
        .buttonStyle(.mnemoPressable)
    }
}

struct LandingPrimaryActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let accessibilityHint: String
    let accessibilityIdentifier: String
    let action: () -> Void
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var usesStackedLayout: Bool {
        dynamicTypeSize >= .xxxLarge
    }

    var body: some View {
        Button {
            HapticManager.impact(.medium)
            action()
        } label: {
            Group {
                if usesStackedLayout {
                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        HStack(spacing: DS.Spacing.sm) {
                            Image(systemName: icon)
                                .font(DS.Typography.headline)
                                .accessibilityHidden(true)

                            Text(title)
                                .font(DS.Typography.headline)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: DS.Spacing.sm)

                            Image(systemName: "chevron.right")
                                .font(DS.Typography.caption1.weight(.semibold))
                                .accessibilityHidden(true)
                        }

                        Text(subtitle)
                            .font(DS.Typography.caption1)
                            .foregroundStyle(DS.Colours.textOnAccent.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    HStack(spacing: DS.Spacing.sm) {
                        Image(systemName: icon)
                            .font(DS.Typography.title3)
                            .frame(width: DS.Spacing.xl, alignment: .leading)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            Text(title)
                                .font(DS.Typography.headline)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(subtitle)
                                .font(DS.Typography.caption1)
                                .foregroundStyle(DS.Colours.textOnAccent.opacity(0.88))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: DS.Spacing.sm)

                        Image(systemName: "chevron.right")
                            .font(DS.Typography.caption1.weight(.semibold))
                            .accessibilityHidden(true)
                    }
                }
            }
            .foregroundStyle(DS.Colours.textOnAccent)
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .frame(maxWidth: .infinity, minHeight: 56.0, alignment: .leading)
            .background(
                DS.Colours.controlAccent,
                in: RoundedRectangle(cornerRadius: DS.CornerRadius.large, style: .continuous)
            )
            .overlay {
                if colorSchemeContrast == .increased {
                    RoundedRectangle(cornerRadius: DS.CornerRadius.large, style: .continuous)
                        .stroke(DS.Colours.textOnAccent, lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.mnemoPressable)
        .accessibilityLabel(title)
        .accessibilityHint(accessibilityHint)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

private struct LandingCaptureAction: Identifiable {
    let id: String
    let title: String
    let icon: String
    let accessibilityHint: String
    let action: () -> Void
}

struct LandingCaptureGroup: View {
    let includesText: Bool
    let onText: () -> Void
    let onVoice: () -> Void
    let onCamera: () -> Void
    let onPhoto: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var usesRows: Bool {
        dynamicTypeSize >= .xxxLarge
    }

    private var actions: [LandingCaptureAction] {
        var actions: [LandingCaptureAction] = []

        if includesText {
            actions.append(
                LandingCaptureAction(
                    id: AccessibilityID.CaptureText.open,
                    title: "Write",
                    icon: "square.and.pencil",
                    accessibilityHint: "Open text capture",
                    action: onText
                )
            )
        }

        actions.append(contentsOf: [
            LandingCaptureAction(
                id: "capture.voice.open",
                title: "Voice",
                icon: "mic.fill",
                accessibilityHint: "Open voice capture",
                action: onVoice
            ),
            LandingCaptureAction(
                id: "capture.camera.open",
                title: "Camera",
                icon: "camera.fill",
                accessibilityHint: "Take a photo for a new memory",
                action: onCamera
            ),
            LandingCaptureAction(
                id: "capture.photo.open",
                title: "Photo",
                icon: "photo.on.rectangle",
                accessibilityHint: "Choose a photo for a new memory",
                action: onPhoto
            ),
        ])

        return actions
    }

    var body: some View {
        Group {
            if usesRows {
                rowLayout
            } else {
                compactLayout
            }
        }
        .padding(.vertical, DS.Spacing.xs)
        .mnemoSurface(.compactControl, cornerRadius: DS.CornerRadius.medium)
    }

    private var rowLayout: some View {
        VStack(spacing: 0) {
            ForEach(actions) { action in
                captureChoice(for: action, layout: .row)

                if action.id != actions.last?.id {
                    horizontalDivider
                }
            }
        }
    }

    private var compactLayout: some View {
        HStack(spacing: 0) {
            ForEach(actions) { action in
                captureChoice(for: action, layout: .compact)

                if action.id != actions.last?.id {
                    verticalDivider
                }
            }
        }
    }

    private var horizontalDivider: some View {
        Divider()
            .padding(.leading, DS.Spacing.xxl)
    }

    private var verticalDivider: some View {
        Rectangle()
            .fill(DS.Colours.separator)
            .frame(width: 1.0, height: DS.Spacing.xl)
    }

    private func captureChoice(
        for action: LandingCaptureAction,
        layout: LandingCaptureChoice.Layout
    ) -> some View {
        LandingCaptureChoice(
            title: action.title,
            icon: action.icon,
            accessibilityHint: action.accessibilityHint,
            accessibilityIdentifier: action.id,
            layout: layout,
            action: action.action
        )
    }
}

struct LandingCaptureChoice: View {
    enum Layout {
        case compact
        case row
    }

    let title: String
    let icon: String
    let accessibilityHint: String
    let accessibilityIdentifier: String
    let layout: Layout
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.impact(.light)
            action()
        } label: {
            Group {
                if layout == .row {
                    HStack(spacing: DS.Spacing.md) {
                        Image(systemName: icon)
                            .font(DS.Typography.headline)
                            .frame(minWidth: 44.0, alignment: .leading)
                        Text(title)
                            .font(DS.Typography.body.weight(.semibold))
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, DS.Spacing.md)
                } else {
                    VStack(spacing: DS.Spacing.xs) {
                        Image(systemName: icon)
                            .font(DS.Typography.headline)
                        Text(title)
                            .font(DS.Typography.caption1.weight(.medium))
                    }
                    .padding(.horizontal, DS.Spacing.xs)
                }
            }
            .foregroundStyle(DS.Colours.accent)
            .frame(maxWidth: .infinity, minHeight: layout == .row ? 48.0 : 56.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(.mnemoPressable)
        .accessibilityLabel(title)
        .accessibilityHint(accessibilityHint)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

struct RecallExampleButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.sm) {
                Text(text)
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(DS.Colours.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: DS.Spacing.sm)

                Image(systemName: "arrow.turn.down.left")
                    .font(DS.Typography.caption1.weight(.semibold))
                    .foregroundStyle(DS.Colours.accent)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm + DS.Spacing.xs)
            .frame(maxWidth: .infinity, minHeight: 48.0, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.mnemoPressable)
        .accessibilityLabel(text)
        .accessibilityHint("Place this question in the Recall field")
    }
}

struct ChatInputBar: View {

    @Binding var text: String
    let focus: FocusState<Bool>.Binding
    let isProcessing: Bool
    let showsCaptureShortcuts: Bool
    let placeholder: String
    let inputAccessibilityHint: String
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
                        .foregroundStyle(DS.Colours.accent)
                        .frame(width: 44.0, height: 44.0)
                }
                .buttonStyle(.mnemoPressable)
                .accessibilityLabel("Add memory")
                .accessibilityHint("Choose how to save a memory")
                .accessibilityIdentifier(AccessibilityID.Chat.captureMenu)
            }

            TextField(
                placeholder,
                text: $text,
                prompt: Text(placeholder).foregroundStyle(DS.Colours.textSecondary),
                axis: .vertical
            )
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textPrimary)
                .lineLimit(1...4)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
                .frame(minHeight: 44.0)
                .background(DS.Colours.controlFallback)
                .overlay {
                    RoundedRectangle(cornerRadius: DS.CornerRadius.large)
                        .stroke(
                            colorSchemeContrast == .increased ? DS.Colours.borderStrong : DS.Colours.separator,
                            lineWidth: colorSchemeContrast == .increased ? 1.5 : 1.0
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
                .focused(focus)
                .onSubmit {
                    onSend()
                }
                .submitLabel(.send)
                .accessibilityLabel("Recall question")
                .accessibilityHint(inputAccessibilityHint)
                .accessibilityIdentifier(AccessibilityID.Chat.input)

            Button(action: onSend) {
                Image(systemName: isProcessing ? "ellipsis" : "arrow.up.circle.fill")
                    .font(.system(size: 32.0, weight: .semibold))
                    .foregroundStyle(sendIsActive ? DS.Colours.accent : DS.Colours.accentDisabled)
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

#if DEBUG
private struct EmptyChatLandingPreview: View {
    let hasSavedMemories: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colours.canvas.ignoresSafeArea()

                ScrollView {
                    EmptyChatLanding(
                        hasSavedMemories: hasSavedMemories,
                        minimumHeight: 620.0,
                        onText: {},
                        onVoice: {},
                        onCamera: {},
                        onPhoto: {},
                        onExample: { _ in }
                    )
                    .padding(DS.Spacing.md)
                }
            }
            .navigationTitle("Mnemo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview("Landing - First Memory - Light") {
    EmptyChatLandingPreview(hasSavedMemories: false)
        .preferredColorScheme(.light)
}

#Preview("Landing - First Memory - Dark") {
    EmptyChatLandingPreview(hasSavedMemories: false)
        .preferredColorScheme(.dark)
}

#Preview("Landing - Ready to Recall") {
    EmptyChatLandingPreview(hasSavedMemories: true)
        .preferredColorScheme(.light)
}

#Preview("Landing - Accessibility Type") {
    EmptyChatLandingPreview(hasSavedMemories: false)
        .environment(\.dynamicTypeSize, .accessibility3)
        .preferredColorScheme(.dark)
}

#Preview("Landing - Recall - Accessibility Type") {
    EmptyChatLandingPreview(hasSavedMemories: true)
        .environment(\.dynamicTypeSize, .accessibility3)
        .preferredColorScheme(.light)
}
#endif
