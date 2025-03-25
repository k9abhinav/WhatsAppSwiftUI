import SwiftUI
import FirebaseFirestore

@MainActor
@Observable
final class FireMessageViewModel {
    private let db = Firestore.firestore()
    private let chatsCollection: CollectionReference
    private let messagesCollection: CollectionReference
    private var messageListener: ListenerRegistration?
    var messages: [FireMessageModel] = []

    init() {
        self.chatsCollection = db.collection("chats")
        self.messagesCollection = db.collection("messages")
        print("FireMessageViewModel initialized") // Debug: Initialization
    }

    func setupMessageListener(for chatId: String) {
        messageListener?.remove() // Remove previous listener if any
        messageListener = messagesCollection
            .whereField("chatId", isEqualTo: chatId)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents, error == nil else {
                    print("Error fetching messages: \(error?.localizedDescription ?? "Unknown error")") // Debug: Error fetching messages
                    return
                }
                self.messages = Array(documents.compactMap { try? $0.data(as: FireMessageModel.self) })
                print("Messages listener triggered for chatId: \(chatId), message count: \(self.messages.count)") // Debug: Listener triggered
            }
        print("Messages listener setup for chatId: \(chatId)") // Debug: Listener setup
    }

    func removeMessageListener() {
        messageListener?.remove()
        print("Messages listener removed") // Debug: Listener removed
    }

    func fetchAllMessages(for chatId: String) async {
        do {
            let snapshot = try await messagesCollection
                .whereField("chatId", isEqualTo: chatId)
                .order(by: "timestamp", descending: false)
                .getDocuments()

            self.messages = snapshot.documents.compactMap { try? $0.data(as: FireMessageModel.self) }
            print("Fetched all messages for chatId: \(chatId), message count: \(self.messages.count)") // Debug: Fetched all messages
        } catch {
            print("Failed to fetch messages: \(error.localizedDescription)") // Debug: Error fetching messages
        }
    }

    func sendTextMessage(
        chatId: String,
        currentUserId: String,
        otherUserId: String,
        content: String
    ) async {
        guard !content.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("Message cannot be empty") // Debug: Empty message
            return
        }

        do {
            let chatSnapshot = try await chatsCollection.document(chatId).getDocument()
            guard let chatData = chatSnapshot.data(),
                  let participants = chatData["participants"] as? [String],
                  participants.contains(currentUserId),
                  participants.contains(otherUserId) else {
                print("Invalid chat participants") // Debug: Invalid chat participants
                return
            }

            let newMessage = FireMessageModel(
                id: UUID().uuidString,
                chatId: chatId,
                messageType: .text,
                content: content,
                senderUserId: currentUserId,
                receiverUserId: otherUserId,
                timestamp: Date(),
                replyToMessageId: nil,
                isForwarded: false
            )

            try await messagesCollection.document(newMessage.id).setData(newMessage.asDictionary())
            try await chatsCollection.document(chatId).updateData(["lastMessageId": newMessage.id])
            print("Message sent successfully, messageId: \(newMessage.id)") // Debug: Message sent
        } catch {
            print("Failed to send message: \(error.localizedDescription)") // Debug: Error sending message
        }
    }

    func deleteTextMessage(for messageId: String) async {
        do {
            try await messagesCollection.document(messageId).delete()
            print("Message deleted successfully, messageId: \(messageId)") // Debug: Message deleted
        } catch {
            print("Failed to delete message: \(error.localizedDescription)") // Debug: Error deleting message
        }
    }
}
