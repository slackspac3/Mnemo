import Foundation
import SwiftUI
import MnemoCore
import MnemoMemory
import MnemoIntelligence

/// ViewModel for ChatView.
/// Manages the conversation history, memory recall, and pattern insights.
@Observable
final class ChatViewModel {

    struct Message: Identifiable {
        let id: UUID
        let role: Role
        let content: String
        let timestamp: Date
        let citedMemoryIds: [UUID]

        enum Role {
            case user
            case assistant
        }

        init(
            id: UUID = UUID(),
            role: Role,
            content: String,
            timestamp: Date = Date(),
            citedMemoryIds: [UUID] = []
        ) {
            self.id = id
            self.role = role
            self.content = content
            self.timestamp = timestamp
            self.citedMemoryIds = citedMemoryIds
        }
    }

    var messages: [Message] = []
    var inputText = ""
    var isProcessing = false
    var errorMessage: String?

    private let promptBuilder = ExtractionPromptBuilder()

    init() {
        messages.append(Message(
            role: .assistant,
            content: "Hi. I'm Mnemo. Tell me things you want to remember, or ask me anything you've already told me."
        ))
    }

    @MainActor
    func send() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isProcessing else { return }

        inputText = ""
        isProcessing = true
        errorMessage = nil

        messages.append(Message(role: .user, content: text))

        do {
            let response = try await recall(query: text)
            messages.append(Message(role: .assistant, content: response))
        } catch {
            errorMessage = "Something went wrong. Try again."
            messages.append(Message(
                role: .assistant,
                content: "I had trouble finding that. Try asking differently."
            ))
        }

        isProcessing = false
    }

    private func recall(query: String) async throws -> String {
        _ = promptBuilder.buildRecallPrompt(query: query, memorySummaries: [])
        try await Task.sleep(for: .milliseconds(600))
        return "I'm searching through your memories. Full recall connects in Phase 9 when the memory store is wired to this view."
    }
}
