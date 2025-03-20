import SwiftUI
import FirebaseFirestore

@MainActor
@Observable
class FireChatViewModel {

    // MARK: - Properties
    var chatMessages: [FireChatModel] = []
    private let firestoreDB = Firestore.firestore()
    private var firestoreListener: ListenerRegistration?
    private let chatCollection = "chats"

    // MARK: - Constants
    private struct QueryFields {
        static let userId = "userId"
        static let timestamp = "timestamp"
    }

    private struct Constants {
        static let replyDelay: TimeInterval = 3.0
    }

    // MARK: - Firestore Real-time Updates

    /// Fetch all chats for a specific user in real-time
    func listenForChatUpdates(for userId: String) {
        stopListening() // Remove previous listener if exists

        firestoreListener = createChatQuery(for: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let snapshot = snapshot else {
                    print("Error listening for chat updates: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                Task { @MainActor in
                    self.chatMessages = self.parseChatsFromSnapshot(snapshot)
                }
            }
    }

    /// Stop listening when view is closed
    func stopListening() {
        firestoreListener?.remove()
        firestoreListener = nil
    }

    // MARK: - Fetch Operations

    /// Fetch all chats for a specific user
    @MainActor func fetchChats(for userId: String) async {
        do {
            let snapshot = try await createChatQuery(for: userId).getDocuments()
            self.chatMessages = parseChatsFromSnapshot(snapshot)
            print("Messages count: \(chatMessages.count)")
        } catch {
            print("Error fetching chats: \(error.localizedDescription)")
        }
    }

    /// Fetch most recent chat for a specific user
    @MainActor func fetchLastChat(for userId: String) async -> FireChatModel? {
        do {
            let snapshot = try await firestoreDB.collection(chatCollection)
                .whereField(QueryFields.userId, isEqualTo: userId)
                .order(by: QueryFields.timestamp, descending: true)
                .limit(to: 1)
                .getDocuments()

            return snapshot.documents.first.flatMap { try? $0.data(as: FireChatModel.self) }
        } catch {
            print("Error fetching last chat: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Message Operations

    /// Send a new message and automatically generate a reply
    func sendMessage(for userId: String, content: String, isFromCurrentUser: Bool) async {
        // Send user message
        let userMessage = createChatMessage(
            content: content,
            isFromCurrentUser: isFromCurrentUser,
            userId: userId
        )

        do {
            try await saveChatMessage(userMessage)

            // Schedule automated reply
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.replyDelay) {
                Task {
                    // Create and send reply message
                    let replyMessage = self.createChatMessage(
                        content: self.generateReply(for: content),
                        isFromCurrentUser: false,
                        userId: userId
                    )

                    try? await self.saveChatMessage(replyMessage)
                }
            }
        } catch {
            print("Error sending message: \(error.localizedDescription)")
        }
    }

    /// Delete a chat message
    func deleteMessage(for messageId: String) async {
        do {
            try await firestoreDB.collection(chatCollection).document(messageId).delete()
        } catch {
            print("Error deleting message: \(error.localizedDescription)")
        }
    }

    // MARK: - Helper Methods

    /// Create a standard Firestore query for chat messages
    private func createChatQuery(for userId: String) -> Query {
        return firestoreDB.collection(chatCollection)
            .whereField(QueryFields.userId, isEqualTo: userId)
            .order(by: QueryFields.timestamp, descending: false)
    }

    /// Parse documents from a snapshot into FireChatModel objects
    private func parseChatsFromSnapshot(_ snapshot: QuerySnapshot) -> [FireChatModel] {
        return snapshot.documents.compactMap { document in
            try? document.data(as: FireChatModel.self)
        }
    }

    /// Create a new chat message model
    private func createChatMessage(content: String, isFromCurrentUser: Bool, userId: String) -> FireChatModel {
        return FireChatModel(
            id: UUID().uuidString,
            content: content,
            isFromCurrentUser: isFromCurrentUser,
            timestamp: Date(),
            userId: userId
        )
    }

    /// Save a chat message to Firestore
    private func saveChatMessage(_ message: FireChatModel) async throws {
        try firestoreDB.collection(chatCollection).document(message.id).setData(from: message)
    }

    /// Generate an automated reply message
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
