import SwiftUI
import FirebaseFirestore

@MainActor
@Observable
class FireChatViewModel {

    // MARK: - Properties
    var chatMessages: [FireChatModel] = []
    private let firestoreDB = Firestore.firestore()
    private var firestoreListeners: [ListenerRegistration] = []
    private let chatCollection = "chats"

    // MARK: - Constants
    private struct QueryFields {
        static let senderUserId = "senderUserId"
        static let receiverUserId = "receiverUserId"
        static let timestamp = "timestamp"
    }

    // MARK: - Firestore Real-time Updates

    /// Listen for chat updates between two users
    func listenForChatUpdates(currentUserId: String, otherUserId: String) {
           stopListening() // Remove previous listeners

           let query1 = firestoreDB.collection(chatCollection)
               .whereField(QueryFields.senderUserId, isEqualTo: currentUserId)
               .whereField(QueryFields.receiverUserId, isEqualTo: otherUserId)

           let query2 = firestoreDB.collection(chatCollection)
               .whereField(QueryFields.senderUserId, isEqualTo: otherUserId)
               .whereField(QueryFields.receiverUserId, isEqualTo: currentUserId)

           let listener1 = query1.addSnapshotListener { [weak self] snapshot, error in
               self?.handleSnapshot(snapshot, error: error)
           }

           let listener2 = query2.addSnapshotListener { [weak self] snapshot, error in
               self?.handleSnapshot(snapshot, error: error)
           }

           firestoreListeners = [listener1, listener2]
       }

    func stopListening() {
        for listener in firestoreListeners {
            listener.remove()
        }
        firestoreListeners.removeAll()
    }
    private func handleSnapshot(_ snapshot: QuerySnapshot?, error: Error?) {
            guard let snapshot = snapshot else {
                print("Error listening for chat updates: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            Task { @MainActor in
                var uniqueMessages = Set(chatMessages) // Prevent duplicates
                uniqueMessages.formUnion(snapshot.documents.compactMap { try? $0.data(as: FireChatModel.self) })
                self.chatMessages = uniqueMessages.sorted(by: { $0.timestamp < $1.timestamp })
            }
        }

    // MARK: - Fetch Operations

    /// Fetch all chat messages between two users
    @MainActor
    func fetchChats(currentUserId: String, otherUserId: String) async {
        do {
            let query1 = firestoreDB.collection(chatCollection)
                .whereField("senderUserId", isEqualTo: currentUserId)
                .whereField("receiverUserId", isEqualTo: otherUserId)

            let query2 = firestoreDB.collection(chatCollection)
                .whereField("senderUserId", isEqualTo: otherUserId)
                .whereField("receiverUserId", isEqualTo: currentUserId)

            let snapshot1 = try await query1.getDocuments()
            let snapshot2 = try await query2.getDocuments()

            // Merge messages from both queries
            // Use a Set to ensure unique messages
            var uniqueMessages = Set<FireChatModel>()

            // Append without duplicates
            uniqueMessages.formUnion(snapshot1.documents.compactMap { try? $0.data(as: FireChatModel.self) })
            uniqueMessages.formUnion(snapshot2.documents.compactMap { try? $0.data(as: FireChatModel.self) })

            // Convert back to sorted array
            self.chatMessages = uniqueMessages.sorted(by: { $0.timestamp < $1.timestamp })

        } catch {
            print("Error fetching chats: \(error.localizedDescription)")
        }
    }

    /// Fetch most recent chat between two users
    func listenAndFetchLastChat(currentUserId: String, otherUserId: String, completion: @escaping (FireChatModel?) -> Void) {
        stopListening() // Ensure we don't duplicate listeners

        let query1 = firestoreDB.collection(chatCollection)
            .whereField(QueryFields.senderUserId, isEqualTo: currentUserId)
            .whereField(QueryFields.receiverUserId, isEqualTo: otherUserId)
            .order(by: QueryFields.timestamp, descending: true) // Get latest message first
            .limit(to: 1)

        let query2 = firestoreDB.collection(chatCollection)
            .whereField(QueryFields.senderUserId, isEqualTo: otherUserId)
            .whereField(QueryFields.receiverUserId, isEqualTo: currentUserId)
            .order(by: QueryFields.timestamp, descending: true)
            .limit(to: 1)

        let listener1 = query1.addSnapshotListener { [weak self] snapshot, error in
            if let message = snapshot?.documents.compactMap({ try? $0.data(as: FireChatModel.self) }).first {
                completion(message) // Send update when a new message arrives
            }
        }

        let listener2 = query2.addSnapshotListener { [weak self] snapshot, error in
            if let message = snapshot?.documents.compactMap({ try? $0.data(as: FireChatModel.self) }).first {
                completion(message)
            }
        }

        firestoreListeners = [listener1, listener2] // Store listeners to remove later
    }


    // MARK: - Message Operations

    /// Send a new message from the current user to another user
    func sendMessage(senderUserId: String, receiverUserId: String, content: String) async {
        let message = FireChatModel(
            id: UUID().uuidString,
            content: content,
            senderUserId: senderUserId,
            receiverUserId: receiverUserId,
            timestamp: Date()
        )

        do {
            try await saveChatMessage(message)
        } catch {
            print("Error sending message: \(error.localizedDescription)")
        }
    }

    /// Delete a chat message
    func deleteMessage(for messageId: String, senderUserId: String, receiverUserId: String) async {
        let query = firestoreDB.collection(chatCollection)
            .whereField("id", isEqualTo: messageId)
            .whereField("senderUserId", isEqualTo: senderUserId)
            .whereField("receiverUserId", isEqualTo: receiverUserId)

        do {
            let snapshot = try await query.getDocuments()
            for document in snapshot.documents {
                try await document.reference.delete()
            }
        } catch {
            print("Error deleting message: \(error.localizedDescription)")
        }
    }

    // MARK: - Helper Methods

    /// Create a query for retrieving messages between two users
    private func fetchChatsBetweenUsers(currentUserId: String, otherUserId: String) async -> [FireChatModel] {
        do {
            let query1 = firestoreDB.collection(chatCollection)
                .whereField(QueryFields.senderUserId, isEqualTo: currentUserId)
                .whereField(QueryFields.receiverUserId, isEqualTo: otherUserId)

            let query2 = firestoreDB.collection(chatCollection)
                .whereField(QueryFields.senderUserId, isEqualTo: otherUserId)
                .whereField(QueryFields.receiverUserId, isEqualTo: currentUserId)

            let snapshot1 = try await query1.getDocuments()
            let snapshot2 = try await query2.getDocuments()

            var messages: [FireChatModel] = []
            messages.append(contentsOf: snapshot1.documents.compactMap { try? $0.data(as: FireChatModel.self) })
            messages.append(contentsOf: snapshot2.documents.compactMap { try? $0.data(as: FireChatModel.self) })

            return messages.sorted(by: { $0.timestamp < $1.timestamp }) // Oldest first
        } catch {
            print("Error fetching chats: \(error.localizedDescription)")
            return []
        }
    }

    /// Parse documents from a snapshot into FireChatModel objects
    private func parseChatsFromSnapshot(_ snapshot: QuerySnapshot) -> [FireChatModel] {
        return snapshot.documents.compactMap { document in
            try? document.data(as: FireChatModel.self)
        }
    }

    /// Save a chat message to Firestore
    private func saveChatMessage(_ message: FireChatModel) async throws {
        try firestoreDB.collection(chatCollection).document(message.id).setData(from: message)
    }
}
