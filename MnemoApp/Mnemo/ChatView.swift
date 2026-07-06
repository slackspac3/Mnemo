import SwiftUI
import SwiftData
import MnemoUI
import MnemoCore

/// Primary chat interface: the main surface for recall queries.
struct ChatView: View {

    @State private var viewModel = ChatViewModel()
    @Environment(NavigationCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

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
                                    MessageBubble(message: message)
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
        }
    }
}

struct MessageBubble: View {

    let message: ChatViewModel.Message

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
                    CitationPill(count: message.citedMemoryIds.count)
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

struct CitationPill: View {

    let count: Int

    private var label: String {
        count == 1 ? "Saved memory" : "\(count) saved memories"
    }

    var body: some View {
        Label(label, systemImage: "bookmark.fill")
            .font(DS.Typography.caption1)
            .foregroundStyle(DS.Colours.accent)
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, DS.Spacing.xs)
            .background(DS.Colours.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.full))
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
