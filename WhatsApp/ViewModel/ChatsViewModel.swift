import SwiftUI
import SwiftData

@MainActor
@Observable
class ChatsViewModel {
    var searchText: String = ""
    var showingSettings: Bool = false
    var isTyping: Bool = false
    func filteredUsers(users: [User]) -> [User] {
        guard !searchText.isEmpty else {
            return users
        }

        let searchTerms = searchText.lowercased().trimmingCharacters(in: .whitespaces)

        return users.filter { user in
            let nameMatch = user.name.lowercased().contains(searchTerms)

            let phoneMatch = user.phone
                .replacingOccurrences(of: " ", with: "")
                .lowercased()
                .contains(searchTerms.replacingOccurrences(of: " ", with: ""))

            return nameMatch || phoneMatch
        }
    }

    func toggleSettings() {
        showingSettings = true
        print("Showing Settings: \(showingSettings)")
    }

    func scrollToBottom(_ scrollProxy: ScrollViewProxy, chats: [Chat]) {
        guard let lastMessage = chats.last else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Small delay to ensure UI updates
            withAnimation {
                scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }

    func sendMessage(user: User, messageText: String, context: ModelContext) {
        guard !messageText.isEmpty else { return }

        let newMessage = Chat(
            content: messageText,
            isFromCurrentUser: true,
            user: user
        )
        context.insert(newMessage)
        isTyping = true

        Task {
            try await Task.sleep(nanoseconds: 1_750_000_000) // Sleep for 1.75 seconds

            let replyMessage = Chat(
                content: generateReply(for: messageText),
                isFromCurrentUser: false,
                user:user
            )
            
            context.insert(replyMessage)
            try? context.save()
            isTyping = false
        }
        try? context.save()
    }

    private func generateReply(for userMessage: String) -> String {
        let replies = [
            "Happy to see you! This is a long message to test the scrolling behavior if it works correctly. It should scroll to the bottom automatically when new messages are added.",
            "Hello ! How are you.",
            "Ok bye! 👋",
            "That's interesting!",
            "Tell me more!",
            "😭",
            "Its Ok!",
            "😂",
            "Let's catch up soon!",
            "👍"
        ]
        return replies.randomElement() ?? "Error in chat reply generation."
    }
}
