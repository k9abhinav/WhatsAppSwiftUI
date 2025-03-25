import SwiftUI
import FirebaseFirestore

@MainActor
@Observable
final class FireChatViewModel {
    private let db = Firestore.firestore()
    private let chatsCollection: CollectionReference
    private let messagesCollection: CollectionReference
    private var chatListener: ListenerRegistration?
    var currentChatId: String?
    var chats: [FireChatModel] = []

    init() {
        self.chatsCollection = db.collection("chats")
        self.messagesCollection = db.collection("messages")
        print("FireChatViewModel initialized") // Debug: Initialization
    }

    func setupChatListener() {
        chatListener?.remove() // Remove previous listener if any
        chatListener = chatsCollection.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self, let documents = snapshot?.documents, error == nil else {
                print("Error fetching chats: \(error?.localizedDescription ?? "Unknown error")") // Debug: Error fetching chats
                return
            }
            self.chats = Array(documents.compactMap { try? $0.data(as: FireChatModel.self) })
            print("Chat listener triggered, chats count: \(self.chats.count)") // Debug: Listener triggered
        }
        print("Chat listener setup") // Debug: Listener setup
    }

    func removeChatListener() {
        chatListener?.remove()
        print("Chat listener removed") // Debug: Listener removed
    }

    func loadChatId(for participants: [String]) async {
        do {
            let querySnapshot = try await chatsCollection
                .whereField("participants", arrayContainsAny: participants)
                .getDocuments()

            for document in querySnapshot.documents {
                let chat = try document.data(as: FireChatModel.self)
                if Set(chat.participants.map { $0 }) == Set(participants) {
                    self.currentChatId = chat.id
                    print("Chat ID loaded: \(chat.id)") // Debug: Chat ID loaded
                    return
                }
            }

            // If no existing chat is found, create a new one
            await createNewChat(for: participants)
        } catch {
            print("Failed to load chat ID: \(error.localizedDescription)") // Debug: Error loading chat ID
        }
    }

    func createNewChat(for participants: [String]) async {
        let newChat = FireChatModel(
            id: UUID().uuidString,
            chatType: .single,
            participants: participants,
            creationDate: Date(),
            lastMessageId: nil
        )

        do {
            try await chatsCollection.document(newChat.id).setData(newChat.toDictionary())
            self.currentChatId = newChat.id
            print("New chat created, chat ID: \(newChat.id)") // Debug: New chat created
        } catch {
            print("Failed to create chat: \(error.localizedDescription)") // Debug: Error creating chat
        }
    }

    func isThereChat(for participants: [String]) async -> Bool {
        do {
            let querySnapshot = try await chatsCollection
                .whereField("participants", arrayContainsAny: participants)
                .getDocuments()

            for document in querySnapshot.documents {
                let chat = try document.data(as: FireChatModel.self)
                if Set(chat.participants) == Set(participants) {
                    print("Chat exists for participants") // Debug: Chat exists
                    return true
                }
            }
        } catch {
            print("Error checking chat existence: \(error.localizedDescription)") // Debug: Error checking chat existence
        }
        print("Chat does not exist for participants") //Debug: chat does not exist
        return false
    }

    func deleteChat(for chatId: String) async {
        do {
            try await chatsCollection.document(chatId).delete()
            try await messagesCollection.whereField("chatId", isEqualTo: chatId).getDocuments().documents.forEach { document in
                Task { try await document.reference.delete() }
            }
            print("Chat deleted, chat ID: \(chatId)") // Debug: Chat deleted
        } catch {
            print("Failed to delete chat: \(error.localizedDescription)") // Debug: Error deleting chat
        }
    }

    func fetchLastMessageDetails(for participants: [String]) async -> (content: String?, timestamp: Date?) {
        do {
            let querySnapshot = try await chatsCollection
                .whereField("participants", arrayContainsAny: participants)
                .getDocuments()

            for document in querySnapshot.documents {
                let chat = try document.data(as: FireChatModel.self)
                if Set(chat.participants) == Set(participants), let lastMessageId = chat.lastMessageId {
                    let messageSnapshot = try await messagesCollection.document(lastMessageId).getDocument()
                    if let messageData = messageSnapshot.data(),
                       let content = messageData["content"] as? String,
                       let timestamp = messageData["timestamp"] as? Timestamp {
                        print("Last message details fetched") //Debug: last message details fetched
                        return (content, timestamp.dateValue())
                    }
                }
            }
        } catch {
            print("Error fetching last message details: \(error.localizedDescription)") // Debug: Error fetching last message details
        }
        print("No last message details found") //Debug: no last message details found
        return (nil, nil)
    }
    private func listenForLastMessages() {
        guard !chats.isEmpty else { return }

        for chat in chats {
            guard let lastMessageId = chat.lastMessageId else { continue }

            messagesCollection.document(lastMessageId).addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let document = snapshot, document.exists else {
                    print("Error listening to last message: \(error?.localizedDescription ?? \"Unknown error\")")
                    return
                }

                if let messageData = document.data(),
                   let content = messageData["content"] as? String,
                   let timestamp = messageData["timestamp"] as? Timestamp {

                    // Find the chat and update its last message content
                    if let index = self.chats.firstIndex(where: { $0.id == chat.id }) {
                        var messageId = self.chats[index].lastMessageId
                        // fix
                        self.chats[index].lastMessageTimestamp = timestamp.dateValue()
                    }
                }
            }
        }
    }

}

extension FireMessageModel {
    func asDictionary() -> [String: Any] {
        return [
            "id": id,
            "chatId": chatId,
            "messageType": messageType.rawValue,
            "content": content,
            "senderUserId": senderUserId,
            "receiverUserId": receiverUserId,
            "timestamp": Timestamp(date: timestamp),
            "replyToMessageId": replyToMessageId ?? NSNull(),
            "isForwarded": isForwarded
        ]
    }
}
