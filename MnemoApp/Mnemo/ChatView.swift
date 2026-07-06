import SwiftUI
import MnemoUI
import MnemoCore

/// Primary chat interface: the main surface for recall queries.
struct ChatView: View {

    @State private var viewModel = ChatViewModel()
    @Environment(NavigationCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ZStack {
                DS.Colours.background.ignoresSafeArea()

                VStack(spacing: DS.Spacing.xs) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: DS.Spacing.sm) {
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
                            .padding(.bottom, DS.Spacing.xxl)
                        }
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
                        onSend: {
                            Task { await viewModel.send() }
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
        HStack {
            if isUser {
                Spacer(minLength: DS.Spacing.xxxl)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: DS.Spacing.xs) {
                Text(message.content)
                    .font(DS.Typography.body)
                    .foregroundStyle(isUser ? DS.ComponentTokens.PrimaryButton.foreground : DS.Colours.textPrimary)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.sm)
                    .background(isUser ? DS.Colours.accent : DS.Colours.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
                    .shadow(
                        color: DS.Shadows.subtle.color,
                        radius: DS.Shadows.subtle.radius,
                        x: DS.Shadows.subtle.x,
                        y: DS.Shadows.subtle.y
                    )

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

struct TypingIndicator: View {
    var body: some View {
        HStack {
            Text("Thinking...")
                .font(DS.Typography.footnote)
                .foregroundStyle(DS.Colours.textSecondary)
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
    let onSend: () -> Void
    let onVoice: () -> Void

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Button(action: onVoice) {
                Image(systemName: "mic.fill")
                    .font(DS.Typography.title2)
                    .foregroundStyle(DS.Colours.accent)
                    .frame(
                        width: DS.ComponentTokens.InputField.height,
                        height: DS.ComponentTokens.InputField.height
                    )
            }

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
                    .font(DS.Typography.title1)
                    .foregroundStyle(text.isEmpty || isProcessing ? DS.Colours.textTertiary : DS.Colours.accent)
            }
            .disabled(text.isEmpty || isProcessing)
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
