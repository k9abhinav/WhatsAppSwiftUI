import SwiftUI
import SwiftData

@Observable
class ChatsViewModel {
    var chatCategories: [String] = ["All","Archived","Family ❤️","Friends","Work","Unread"]

    func filteredUsers(users: [User], searchText: String) -> [User] {
        guard !searchText.isEmpty else {
            return users.sorted {
                       ($0.chats.last?.timestamp ?? .distantPast) > ($1.chats.last?.timestamp ?? .distantPast)
            }
        }

        let searchTerms = searchText.lowercased().trimmingCharacters(in: .whitespaces)

        return users.filter { user in
            let nameMatch = user.name.lowercased().contains(searchTerms)
            let phoneMatch = user.phone.replacingOccurrences(of: " ", with: "")
                .lowercased()
                .contains(searchTerms.replacingOccurrences(of: " ", with: ""))
            return nameMatch || phoneMatch
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

        Task { @MainActor in
            try await Task.sleep(nanoseconds: 2_000_000_000)
            let replyMessage = Chat(
                content: generateReply(for: messageText),
                isFromCurrentUser: false,
                user: user
            )
            context.insert(replyMessage)
            try? context.save()
        }
        try? context.save()
    }

    private func generateReply(for userMessage: String) -> String {
        let replies = [
            "Happy to see you! This is a long message to test scrolling behavior.",
            "Hello! How are you?",
            "Ok bye! 👋",
            "That's interesting!",
            "Tell me more!",
            "😭",
            "It's okay!",
            "😂",
            "Let's catch up soon!",
            "👍"
        ]
        return replies.randomElement() ?? "Error in chat reply generation."
    }
  
}
