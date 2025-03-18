import SwiftUI
import FirebaseFirestore

@MainActor
@Observable
class FireChatViewModel  {

    @MainActor var messages: [FireChatModel] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    /// Fetch all chats for a specific user in real-time
    func listenForChatUpdates(for userId: String) {
        listener?.remove() // Remove previous listener if exists

        listener = db.collection("chats")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let snapshot = snapshot else {
                    print("Error listening for chat updates: \(error?.localizedDescription ?? "Unknown error")")
                    return                }

                var fetchedMessages: [FireChatModel] = []
                for doc in snapshot.documents {
                    do {
                        let message = try doc.data(as: FireChatModel.self)
                        fetchedMessages.append(message)
                    } catch {
                        print("Failed to decode document \(doc.documentID): \(error)")
                    }
                }

                Task { @MainActor in
                    self.messages = fetchedMessages
                }
            }
    }

    /// Stop listening when view is closed
    func stopListening() {
        listener?.remove()
        listener = nil
    }

    /// Fetch all chats for a specific user
    @MainActor func fetchChats(for userId: String) async {
        do {
            let snapshot = try await db.collection("chats")
                .whereField("userId", isEqualTo: userId)
                .order(by: "timestamp", descending: false)
                .getDocuments()

            var fetchedMessages: [FireChatModel] = []
            for doc in snapshot.documents {
                do {
                    let message = try doc.data(as: FireChatModel.self)
                    fetchedMessages.append(message)
                } catch {
                    print("Failed to decode document \(doc.documentID): \(error)")
                }
            }

            self.messages = fetchedMessages
            print("Messages count: \(messages.count)")
        } catch {
            print("Error fetching chats: \(error.localizedDescription)")
        }
    }

    /// Send a new message
    func sendMessage(for userId: String, content: String, isFromCurrentUser: Bool) async {
        let newMessage = FireChatModel(
            id: UUID().uuidString,
            content: content,
            isFromCurrentUser: isFromCurrentUser,
            timestamp: Date(),
            userId: userId
        )

        do {
            try db.collection("chats").document(newMessage.id).setData(from: newMessage)

            // Delay the reply message by 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                Task {
                    let newReplyMessage = FireChatModel(
                        id: UUID().uuidString,
                        content: self.generateReply(for: content),
                        isFromCurrentUser: false,
                        timestamp: Date(),
                        userId: userId
                    )
                    do {
                        try self.db.collection("chats").document(newReplyMessage.id)
                            .setData(from: newReplyMessage)
                    } catch {
                        print("Error sending reply message: \(error.localizedDescription)")
                    }
                }
            }

        } catch {
            print("Error sending message: \(error.localizedDescription)")
        }
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

    /// Delete a chat message
    func deleteMessage(for messageId: String) async {
        do {
            try await db.collection("chats").document(messageId).delete()
        } catch {
            print("Error deleting message: \(error.localizedDescription)")
        }
    }

    @MainActor func fetchLastChat(for userId: String) async -> FireChatModel? {
        do {
            let snapshot = try await db.collection("chats")
                .whereField("userId", isEqualTo: userId)
                .order(by: "timestamp", descending: true)
                .limit(to: 1)
                .getDocuments()

            if let doc = snapshot.documents.first {
                return try doc.data(as: FireChatModel.self)
            }
        } catch {
            print("Error fetching last chat: \(error.localizedDescription)")
        }
        return nil
    }
}
