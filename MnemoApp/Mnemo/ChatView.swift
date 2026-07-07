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
    @Query(sort: \MemoryRecord.createdAt, order: .reverse) private var records: [MemoryRecord]
    @State private var selectedSourceMemory: ChatSelectedMemory?

    private var activeRecords: [MemoryRecord] {
        records.filter { !$0.isArchived }
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ZStack {
                DS.Colours.background.ignoresSafeArea()

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
                            withAnimation(DS.Animation.standard) {
                                proxy.scrollTo(ChatScrollAnchor.bottom, anchor: .bottom)
                            }
                        }
                    }

                    ChatInputBar(
                        text: $viewModel.inputText,
                        isProcessing: viewModel.isProcessing,
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
                    HStack(spacing: DS.Spacing.xs) {
                        Button {
                            withAnimation(DS.Animation.standard) {
                                viewModel.resetConversation()
                            }
                        } label: {
                            Image(systemName: "house.fill")
                                .font(DS.Typography.headline)
                                .foregroundStyle(DS.Colours.accent)
                                .frame(width: 44.0, height: 44.0)
                        }
                        .accessibilityLabel("Home")
                        .accessibilityHint("Return to the memory landing screen")
                        .accessibilityIdentifier("chat.homeButton")

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
                    Button {
                        coordinator.present(.captureText)
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(DS.Typography.headline)
                            .foregroundStyle(DS.Colours.accent)
                    }
                    .accessibilityLabel("Write memory")
                    .accessibilityIdentifier(AccessibilityID.CaptureText.open)
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
                    .background(isUser ? DS.Colours.accent : DS.Colours.surface)
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

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Label(title, systemImage: "bookmark.fill")
                .font(DS.Typography.caption1)
                .foregroundStyle(DS.Colours.accent)
                .accessibilityLabel(title)

            if citations.isEmpty {
                Text(fallbackCount == 1 ? "Source memory is saved locally." : "\(fallbackCount) source memories are saved locally.")
                    .font(DS.Typography.caption1)
                    .foregroundStyle(DS.Colours.textSecondary)
                    .padding(DS.Spacing.sm)
                    .background(DS.Colours.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
            } else {
                ForEach(citations.prefix(3)) { citation in
                    Button {
                        onSourceTap(citation.id)
                    } label: {
                        HStack(alignment: .center, spacing: DS.Spacing.sm) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(DS.Typography.caption1)
                                .foregroundStyle(DS.Colours.accent)
                                .frame(width: DS.Spacing.md)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                                Text(citation.source)
                                    .font(DS.Typography.caption2)
                                    .foregroundStyle(DS.Colours.textTertiary)
                                    .accessibilityIdentifier(AccessibilityID.Chat.sourceType)
                                Text("\"\(citation.summary)\"")
                                    .font(DS.Typography.caption1)
                                    .foregroundStyle(DS.Colours.textSecondary)
                                    .lineLimit(3)
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer(minLength: DS.Spacing.xs)

                            Image(systemName: "chevron.right")
                                .font(DS.Typography.caption1)
                                .foregroundStyle(DS.Colours.textTertiary)
                                .accessibilityHidden(true)
                        }
                        .padding(DS.ComponentTokens.SourceCard.padding)
                        .background(DS.ComponentTokens.SourceCard.background)
                        .overlay {
                            RoundedRectangle(cornerRadius: DS.ComponentTokens.SourceCard.cornerRadius)
                                .stroke(DS.ComponentTokens.SourceCard.border, lineWidth: 1.0)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: DS.ComponentTokens.SourceCard.cornerRadius))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(citation.source) source memory")
                    .accessibilityValue(citation.summary)
                    .accessibilityHint("Open source memory details")
                    .accessibilityIdentifier(citation.id == citations.first?.id ? AccessibilityID.Chat.sourceCardPrimary : AccessibilityID.Chat.sourceCard)
                }
            }
        }
        .frame(maxWidth: 300.0, alignment: .leading)
    }

    private var title: String {
        fallbackCount == 1 ? "Source memory" : "Source memories"
    }
}

struct MissingSourceView: View {

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.md) {
                Image(systemName: "exclamationmark.magnifyingglass")
                    .font(DS.Typography.largeTitle)
                    .foregroundStyle(DS.Colours.textTertiary)

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
    var body: some View {
        HStack {
            HStack(spacing: DS.Spacing.xs) {
                ProgressView()
                    .controlSize(.small)
                Text("Looking through memories")
                    .font(DS.Typography.footnote)
                    .foregroundStyle(DS.Colours.textSecondary)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .background(DS.Colours.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
                .shadow(
                    color: DS.Shadows.subtle.color,
                    radius: DS.Shadows.subtle.radius,
                    x: DS.Shadows.subtle.x,
                    y: DS.Shadows.subtle.y
                )
            Spacer(minLength: DS.Spacing.xxxl)
        }
    }
}

struct EmptyChatLanding: View {

    let hasSavedMemories: Bool
    let onText: () -> Void
    let onVoice: () -> Void
    let onCamera: () -> Void
    let onPhoto: () -> Void
    let onExample: (String) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: DS.Spacing.sm),
        GridItem(.flexible(), spacing: DS.Spacing.sm),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack(alignment: .top, spacing: DS.Spacing.md) {
                MnemoLogoMark(size: 44.0, style: .subtle)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("What do you want to remember?")
                        .font(DS.Typography.title1)
                        .foregroundStyle(DS.Colours.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Save a thought, detail, decision or reminder. Ask Mnemo about it later in plain language.")
                        .font(DS.Typography.subheadline)
                        .foregroundStyle(DS.Colours.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Text("Save a memory")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colours.textPrimary)

                LandingActionButton(
                    title: "Write memory",
                    subtitle: "Type a detail, decision or reminder",
                    icon: "square.and.pencil",
                    tint: DS.Colours.accent,
                    prominence: .primary,
                    accessibilityIdentifier: AccessibilityID.CaptureText.open,
                    action: onText
                )

                LazyVGrid(columns: columns, spacing: DS.Spacing.sm) {
                    LandingActionButton(
                        title: "Voice",
                        subtitle: "Speak",
                        icon: "mic.fill",
                        tint: DS.Colours.accent,
                        prominence: .secondary,
                        accessibilityIdentifier: "capture.voice.open",
                        action: onVoice
                    )
                    LandingActionButton(
                        title: "Camera",
                        subtitle: "Capture",
                        icon: "camera.fill",
                        tint: DS.Colours.success,
                        prominence: .secondary,
                        accessibilityIdentifier: "capture.camera.open",
                        action: onCamera
                    )
                    LandingActionButton(
                        title: "Photo",
                        subtitle: "Choose",
                        icon: "photo.on.rectangle",
                        tint: DS.Colours.warning,
                        prominence: .secondary,
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
                    Label("Save your first memory to unlock recall.", systemImage: "arrow.turn.down.right")
                        .font(DS.Typography.subheadline)
                        .foregroundStyle(DS.Colours.textSecondary)
                    Label("Stored locally on this iPhone.", systemImage: "lock.shield")
                        .font(DS.Typography.footnote)
                        .foregroundStyle(DS.Colours.textTertiary)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.xs)
        .padding(.top, DS.Spacing.md)
        .padding(.bottom, DS.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier(AccessibilityID.Chat.landing)
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

                Text("Once Mnemo has something saved, this chat becomes your recall screen.")
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
            .buttonStyle(.plain)
        }
        .padding(DS.Spacing.md)
        .background(DS.Colours.surface)
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
        .buttonStyle(.plain)
    }
}

struct LandingActionButton: View {
    enum Prominence {
        case primary
        case secondary
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
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: icon)
                    .font(DS.Typography.title2)
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
            }
            .frame(maxWidth: .infinity, minHeight: prominence == .primary ? 72.0 : 76.0, alignment: .leading)
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
            .shadow(
                color: DS.Shadows.subtle.color,
                radius: DS.Shadows.subtle.radius,
                x: DS.Shadows.subtle.x,
                y: DS.Shadows.subtle.y
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var backgroundColor: Color {
        prominence == .primary ? DS.Colours.accent : DS.Colours.surface
    }

    private var iconColor: Color {
        prominence == .primary ? .white : tint
    }

    private var titleColor: Color {
        prominence == .primary ? .white : DS.Colours.textPrimary
    }

    private var subtitleColor: Color {
        prominence == .primary ? .white.opacity(0.86) : DS.Colours.textSecondary
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
        .buttonStyle(.plain)
    }
}

struct ChatInputBar: View {

    @Binding var text: String
    let isProcessing: Bool
    let onText: () -> Void
    let onCamera: () -> Void
    let onPhoto: () -> Void
    let onSend: () -> Void
    let onVoice: () -> Void

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isProcessing
    }

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            Menu {
                Button(action: onCamera) {
                    Label("Take Photo", systemImage: "camera")
                }

                Button(action: onPhoto) {
                    Label("Choose Photo", systemImage: "photo")
                }

                Button(action: onText) {
                    Label("Write Memory", systemImage: "square.and.pencil")
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24.0, weight: .semibold))
                    .foregroundStyle(DS.Colours.accent)
                    .frame(width: 40.0, height: 44.0)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add memory")
            .accessibilityHint("Choose how to save a memory")
            .accessibilityIdentifier(AccessibilityID.Main.capture)

            Button(action: onVoice) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 24.0, weight: .semibold))
                    .foregroundStyle(DS.Colours.accent)
                    .frame(
                        width: 40.0,
                        height: 44.0
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Record voice memory")
            .accessibilityHint("Open voice capture")
            .accessibilityIdentifier("capture.voice.open")

            TextField("Ask about a saved memory...", text: $text, axis: .vertical)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textPrimary)
                .lineLimit(1...4)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
                .background(DS.Colours.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.full))
                .onSubmit {
                    onSend()
                }
                .submitLabel(.send)
                .accessibilityIdentifier(AccessibilityID.Chat.input)

            Button(action: onSend) {
                Image(systemName: isProcessing ? "ellipsis" : "arrow.up.circle.fill")
                    .font(.system(size: 32.0, weight: .semibold))
                    .foregroundStyle(canSend ? DS.Colours.accent : DS.Colours.textTertiary)
                    .frame(width: 44.0, height: 44.0)
            }
            .disabled(!canSend)
            .buttonStyle(.plain)
            .accessibilityLabel("Send")
            .accessibilityHint("Ask Mnemo to recall a saved memory")
            .accessibilityIdentifier(AccessibilityID.Chat.send)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
        .background(DS.Colours.surface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(DS.Colours.surfaceSecondary)
                .frame(height: DS.Spacing.xs / DS.Spacing.xs)
        }
    }
}
