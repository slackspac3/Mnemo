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

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ZStack {
                DS.Colours.background.ignoresSafeArea()

                VStack(spacing: DS.Spacing.xs) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: DS.Spacing.md) {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(
                                        message: message,
                                        onSourceTap: { id in
                                            selectedSourceMemory = ChatSelectedMemory(id: id)
                                        }
                                    )
                                        .id(message.id)
                                }

                                if viewModel.isProcessing {
                                    TypingIndicator()
                                }
                            }
                            .padding(.horizontal, DS.Spacing.md)
                            .padding(.top, DS.Spacing.md)
                            .padding(.bottom, DS.Spacing.xl)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onChange(of: viewModel.messages.count) {
                            if let last = viewModel.messages.last {
                                withAnimation(DS.Animation.standard) {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    ChatInputBar(
                        text: $viewModel.inputText,
                        isProcessing: viewModel.isProcessing,
                        onText: {
                            coordinator.present(.captureText)
                        },
                        onPhoto: {
                            coordinator.present(.captureImage)
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
                    Button {
                        coordinator.present(.settings)
                    } label: {
                        Image(systemName: "gearshape")
                            .font(DS.Typography.headline)
                            .foregroundStyle(DS.Colours.accent)
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
                }
            }
            .sheet(item: $selectedSourceMemory) { selected in
                if let record = records.first(where: { $0.id == selected.id }) {
                    MemoryDetailView(record: record)
                } else {
                    MissingSourceView()
                }
            }
        }
    }
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
                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            HStack(spacing: DS.Spacing.xs) {
                                Text(citation.source)
                                    .font(DS.Typography.caption2)
                                    .foregroundStyle(DS.Colours.textTertiary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(DS.Typography.caption2)
                                    .foregroundStyle(DS.Colours.textTertiary)
                            }

                            Text("\"\(citation.summary)\"")
                                .font(DS.Typography.caption1)
                                .foregroundStyle(DS.Colours.textSecondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(DS.Spacing.sm)
                        .background(DS.Colours.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: 280.0, alignment: .leading)
    }

    private var title: String {
        fallbackCount == 1 ? "Memory used" : "Sources"
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

struct ChatInputBar: View {

    @Binding var text: String
    let isProcessing: Bool
    let onText: () -> Void
    let onPhoto: () -> Void
    let onSend: () -> Void
    let onVoice: () -> Void

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            Menu {
                Button(action: onPhoto) {
                    Label("Photo", systemImage: "photo")
                }

                Button(action: onText) {
                    Label("Text", systemImage: "square.and.pencil")
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24.0, weight: .semibold))
                    .foregroundStyle(DS.Colours.accent)
                    .frame(width: 40.0, height: 44.0)
            }
            .buttonStyle(.plain)

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

            TextField("Ask or tell Mnemo anything...", text: $text, axis: .vertical)
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

            Button(action: onSend) {
                Image(systemName: isProcessing ? "ellipsis" : "arrow.up.circle.fill")
                    .font(.system(size: 32.0, weight: .semibold))
                    .foregroundStyle(text.isEmpty || isProcessing ? DS.Colours.textTertiary : DS.Colours.accent)
                    .frame(width: 44.0, height: 44.0)
            }
            .disabled(text.isEmpty || isProcessing)
            .buttonStyle(.plain)
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
