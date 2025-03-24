import Firebase
import FirebaseFirestore
import SwiftUI

@MainActor
@Observable final class FireChatViewModel {
    // MARK: - Properties
    private let db = Firestore.firestore()
    private let messagesCollection: CollectionReference
    private let chatsCollection: CollectionReference
    private var listener: ListenerRegistration?

    var messages: [FireMessageModel] = []
    var errorMessage: String = ""
    var showError: Bool = false

    // MARK: - Init
    init() {
        self.messagesCollection = db.collection("messages")
        self.chatsCollection = db.collection("chats")
    }


    // MARK: - Send Message
    func sendMessage(chatId: String, senderId: String, receiverId: String, content: String, messageType: MessageType, replyToMessageId: String? = nil, isForwarded: Bool = false) async {
        guard !content.isEmpty else {
            showError("Message cannot be empty")
            return
        }

        let newMessage = FireMessageModel(
            id: UUID().uuidString,
            chatId: chatId,
            messageType: messageType,
            content: content,
            senderUserId: senderId,
            receiverUserId: receiverId,
            timestamp: Date(),
            replyToMessageId: replyToMessageId,
            isForwarded: isForwarded
        )

        do {
            try await messagesCollection.document(newMessage.id).setData(newMessage.asDictionary())

            // Update lastMessageId in chat
            try await chatsCollection.document(chatId).updateData(["lastMessageId": newMessage.id])
        } catch {
            showError("Failed to send message: \(error.localizedDescription)")
        }
    }
    /// Fetch or Create Chat ID between two users
       func getOrCreateChatId(loggedInUserId: String, otherUserId: String) async -> String? {
           do {
               let snapshot = try await chatsCollection
                   .whereField("chatType", isEqualTo: ChatType.single.rawValue)
                   .whereField("partcipants", arrayContains: loggedInUserId)
                   .getDocuments()

               // Check if a chat already exists between the two users
               for document in snapshot.documents {
                   let chat = try document.data(as: FireChatModel.self)
                   let participantIds = chat.partcipants.map { $0.id }

                   if participantIds.contains(otherUserId) {
                       return chat.id // Return existing chatId
                   }
               }

               // If no existing chat found, create a new chat
               let newChat = FireChatModel(
                   id: UUID().uuidString,
                   chatType: .single,
                   partcipants: [FireUserModel(id: loggedInUserId), FireUserModel(id: otherUserId)],
                   creationDate: Date()
               )

               try await chatsCollection.document(newChat.id).setData(newChat.asDictionary())
               return newChat.id

           } catch {
               showError("Failed to fetch chat: \(error.localizedDescription)")
               return nil
           }
       }
    // MARK: - Delete Message
    func deleteMessage(messageId: String, chatId: String) async {
        do {
            try await messagesCollection.document(messageId).delete()
            messages.removeAll { $0.id == messageId }
        } catch {
            showError("Failed to delete message: \(error.localizedDescription)")
        }
    }

    // MARK: - Load Messages with Real-Time Updates
    func observeMessages(chatId: String) {
        listener?.remove() // Remove previous listener if any

        listener = messagesCollection
            .whereField("chatId", isEqualTo: chatId)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    self.showError("Failed to fetch messages: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }
                self.messages = documents.compactMap { try? $0.data(as: FireMessageModel.self) }
            }
    }

    // MARK: - Helper Functions
    // MARK: - Stop Listener (Call when leaving ChatDetailView)
    func stopObservingMessages() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Show Error Helper
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - FireMessageModel Extension
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























//import SwiftUI
//import FirebaseFirestore
//
//@MainActor
//@Observable
//class FireChatViewModel {
//
//    // MARK: - Properties
//    var chatMessages: [FireMessageModel] = []
//    private let firestoreDB = Firestore.firestore()
//    private var firestoreListeners: [ListenerRegistration] = []
//    private let chatCollection = "chats"
//
//    // MARK: - Constants
//    private struct QueryFields {
//        static let senderUserId = "senderUserId"
//        static let receiverUserId = "receiverUserId"
//        static let timestamp = "timestamp"
//    }
//
//    // MARK: - Firestore Real-time Updates
//
//    /// Listen for chat updates between two users
//    @MainActor
//    func listenForChatUpdates(currentUserId: String, otherUserId: String) {
//        // Stop previous listeners only if they exist
//        if !firestoreListeners.isEmpty {
//            stopListening()
//        }
//
//        let query1 = firestoreDB.collection(chatCollection)
//            .whereField(QueryFields.senderUserId, isEqualTo: currentUserId)
//            .whereField(QueryFields.receiverUserId, isEqualTo: otherUserId)
//
//        let query2 = firestoreDB.collection(chatCollection)
//            .whereField(QueryFields.senderUserId, isEqualTo: otherUserId)
//            .whereField(QueryFields.receiverUserId, isEqualTo: currentUserId)
//
//        let listener1 = query1.addSnapshotListener { snapshot, error in
//            self.handleSnapshot(snapshot, error: error)
//        }
//
//        let listener2 = query2.addSnapshotListener { snapshot, error in
//            self.handleSnapshot(snapshot, error: error)
//        }
//
//        firestoreListeners.append(listener1)
//        firestoreListeners.append(listener2)
//    }
//
//    func stopListening() {
//        for listener in firestoreListeners {
//            listener.remove()
//        }
//        firestoreListeners.removeAll()
//    }
//
//    @MainActor
//    private func handleSnapshot(_ snapshot: QuerySnapshot?, error: Error?) {
//        guard let snapshot = snapshot else {
//            print("Error listening for chat updates: \(error?.localizedDescription ?? "Unknown error")")
//            return
//        }
//
//        var uniqueMessages = Set(chatMessages)
//        uniqueMessages.formUnion(snapshot.documents.compactMap { try? $0.data(as: FireMessageModel.self) })
//
//        // Directly update chatMessages
//        chatMessages = uniqueMessages.sorted(by: { $0.timestamp < $1.timestamp })
//    }
//
//    // MARK: - Fetch Operations
//
//    /// Fetch all chat messages between two users
//    @MainActor
//    func fetchChats(currentUserId: String, otherUserId: String) async {
//        do {
//            let query1 = firestoreDB.collection(chatCollection)
//                .whereField("senderUserId", isEqualTo: currentUserId)
//                .whereField("receiverUserId", isEqualTo: otherUserId)
//
//            let query2 = firestoreDB.collection(chatCollection)
//                .whereField("senderUserId", isEqualTo: otherUserId)
//                .whereField("receiverUserId", isEqualTo: currentUserId)
//
//            let snapshot1 = try await query1.getDocuments()
//            let snapshot2 = try await query2.getDocuments()
//
//            // Merge messages from both queries
//            // Use a Set to ensure unique messages
//            var uniqueMessages = Set<FireMessageModel>()
//
//            // Append without duplicates
//            uniqueMessages.formUnion(snapshot1.documents.compactMap { try? $0.data(as: FireMessageModel.self) })
//            uniqueMessages.formUnion(snapshot2.documents.compactMap { try? $0.data(as: FireMessageModel.self) })
//
//            // Convert back to sorted array
//            self.chatMessages = uniqueMessages.sorted(by: { $0.timestamp < $1.timestamp })
//
//        } catch {
//            print("Error fetching chats: \(error.localizedDescription)")
//        }
//    }
//
//    /// Fetch most recent chat between two users
//    @MainActor
//    func listenAndFetchLastChat(currentUserId: String, otherUserId: String, completion: @escaping (FireMessageModel?) -> Void) {
//        let query1 = firestoreDB.collection(chatCollection)
//            .whereField(QueryFields.senderUserId, isEqualTo: currentUserId)
//            .whereField(QueryFields.receiverUserId, isEqualTo: otherUserId)
//            .order(by: QueryFields.timestamp, descending: true)
//            .limit(to: 1)
//
//        let query2 = firestoreDB.collection(chatCollection)
//            .whereField(QueryFields.senderUserId, isEqualTo: otherUserId)
//            .whereField(QueryFields.receiverUserId, isEqualTo: currentUserId)
//            .order(by: QueryFields.timestamp, descending: true)
//            .limit(to: 1)
//
//        let listener1 = query1.addSnapshotListener { snapshot1, error1 in
//            self.handleLastMessageSnapshot(snapshot1, error: error1, completion: completion)
//        }
//
//        let listener2 = query2.addSnapshotListener { snapshot2, error2 in
//            self.handleLastMessageSnapshot(snapshot2, error: error2, completion: completion)
//        }
//
//        firestoreListeners.append(listener1)
//        firestoreListeners.append(listener2)
//    }
//
//    /// Handles Firestore snapshot updates for last message
//    private func handleLastMessageSnapshot(_ snapshot: QuerySnapshot?, error: Error?, completion: @escaping (FireMessageModel?) -> Void) {
//        if let error = error {
//            print("Error fetching last message: \(error.localizedDescription)")
//            completion(nil)
//            return
//        }
//
//        var allMessages: [FireMessageModel] = []
//
//        if let docs = snapshot?.documents {
//            allMessages.append(contentsOf: docs.compactMap { try? $0.data(as: FireMessageModel.self) })
//        }
//
//        let sortedMessages = allMessages.sorted { $0.timestamp < $1.timestamp }
//        let lastMessage = sortedMessages.last
//
//        if let lastMessage = lastMessage {
//            print("🔥 Debug: Last message updated - \(lastMessage.content)")
//        } else {
//            print("🔥 Debug: No last message found")
//        }
//
//        completion(lastMessage)
//    }
//
//    // MARK: - Message Operations
//
//    /// Send a new message from the current user to another user
//    func sendMessage(senderUserId: String, receiverUserId: String, content: String) async {
//        let message = FireMessageModel(
//            id: UUID().uuidString,
//            chatId: UUID().uuidString, // Add chatID
//            messageType: .text, // Add messageType
//            content: content,
//            senderUserId: senderUserId,
//            receiverUserId: receiverUserId,
//            timestamp: Date(),
//            isForwarded: false // add isForwarded
//        )
//
//        do {
//            try await saveChatMessage(message)
//        } catch {
//            print("Error sending message: \(error.localizedDescription)")
//        }
//    }
//
//    /// Delete a chat message
//    func deleteMessage(for messageId: String, senderUserId: String, receiverUserId: String) async {
//        let query = firestoreDB.collection(chatCollection)
//            .whereField("id", isEqualTo: messageId)
//            .whereField("senderUserId", isEqualTo: senderUserId)
//            .whereField("receiverUserId", isEqualTo: receiverUserId)
//
//        do {
//            let snapshot = try await query.getDocuments()
//            for document in snapshot.documents {
//                try await document.reference.delete()
//            }
//        } catch {
//            print("Error deleting message: \(error.localizedDescription)")
//        }
//    }
//
//    // MARK: - Helper Methods
//
//    /// Create a query for retrieving messages between two users
//    private func fetchChatsBetweenUsers(currentUserId: String, otherUserId: String) async -> [FireMessageModel] {
//        do {
//            let query1 = firestoreDB.collection(chatCollection)
//                .whereField(QueryFields.senderUserId, isEqualTo: currentUserId)
//                .whereField(QueryFields.receiverUserId, isEqualTo: otherUserId)
//
//            let query2 = firestoreDB.collection(chatCollection)
//                .whereField(QueryFields.senderUserId, isEqualTo: otherUserId)
//                .whereField(QueryFields.receiverUserId, isEqualTo: currentUserId)
//
//            let snapshot1 = try await query1.getDocuments()
//            let snapshot2 = try await query2.getDocuments()
//
//            var messages: [FireMessageModel] = []
//            messages.append(contentsOf: snapshot1.documents.compactMap { try? $0.data(as: FireMessageModel.self) })
//            messages.append(contentsOf: snapshot2.documents.compactMap { try? $0.data(as: FireMessageModel.self) })
//
//            return messages.sorted(by: { $0.timestamp < $1.timestamp }) // Oldest first
//        } catch {
//            print("Error fetching chats: \(error.localizedDescription)")
//            return []
//        }
//    }
//
//    /// Parse documents from a snapshot into FireChatModel objects
//        private func parseChatsFromSnapshot(_ snapshot: QuerySnapshot) -> [FireMessageModel] {
//            return snapshot.documents.compactMap { document in
//                try? document.data(as: FireMessageModel.self)
//            }
//        }
//
//        /// Save a chat message to Firestore
//        private func saveChatMessage(_ message: FireMessageModel) async throws {
//            try firestoreDB.collection(chatCollection).document(message.id).setData(from: message)
//        }
//    }
