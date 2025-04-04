import SwiftUI
import FirebaseFirestore
import Observation

@MainActor
@Observable
final class FireChatViewModel {
    private let db = Firestore.firestore()
    private let chatsCollection: CollectionReference
    private let messagesCollection: CollectionReference
    private var chatListener: ListenerRegistration?
    private var lastMessageListener: ListenerRegistration?
    private var messageDetailsListener: ListenerRegistration?
    var currentChatId: String?
    var chats: [FireChatModel] = []
    var triggeredUpdate: Bool = false

    init() {
        self.chatsCollection = db.collection("chats")
        self.messagesCollection = db.collection("messages")
        print("FireChatViewModel initialized -------- ✅-----------") // Debug: Initialization
    }

    //MARK: - Chat listener
    func setupChatListener(currentUserId: String) {
        chatListener?.remove() // Remove previous listener if any
        chatListener = chatsCollection
            .whereField("participants", arrayContains: currentUserId) // ✅ Filter only relevant chats
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents, error == nil else {
                    print("Error fetching chats: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                self.chats = documents.compactMap { try? $0.data(as: FireChatModel.self) }

                Task { self.triggeredUpdate = true }
                print("\n")
                print("Chat listener triggered, chats count: \(self.chats.count)")

            }
        print("Chat listener setup -----------✅------------")
    }

    //MARK: - RemoveChatListener
    func removeChatListener() {
        chatListener?.remove()
        chatListener = nil
        print("Chat listener removed ---------❌-----------") // Debug: Listener removed
    }

    //MARK: -loadChatId
    func loadChatId(for participants: [String]) async {
        do {
            let querySnapshot = try await chatsCollection
                .whereField("participants", arrayContainsAny: participants)
                .getDocuments()

            for document in querySnapshot.documents {
                let chat = try document.data(as: FireChatModel.self)
                if Set(chat.participants.map { $0 }) == Set(participants) {
                    self.currentChatId = chat.id
                    print("Chat ID loaded: \(chat.id) for \(participants)") // Debug: Chat ID loaded
                    print("\n")
                    return
                }
            }
            await createNewChat(for: participants)
        } catch {
            print("Failed to load chat ID: \(error.localizedDescription)") // Debug: Error loading chat ID
        }
    }
    // MARK: GET CHAT ID
    func getChatId(for participants: [String]) async -> String? {
        do {
            let querySnapshot = try await chatsCollection
                .whereField("participants", arrayContainsAny: participants)
                .getDocuments()

            for document in querySnapshot.documents {
                let chat = try document.data(as: FireChatModel.self)
                if Set(chat.participants) == Set(participants) {
                    print("Found Chat ID : \(chat.id) of \(participants)")
                    return chat.id
                }
            }
            return nil // Chat not found
        } catch {
            print("Failed to get chat ID ------❌-----------: \(error.localizedDescription)")
            return nil
        }
    }
    //MARK: -createNewChat
    func createNewChat(for participants: [String]) async {
        let newChat = FireChatModel(
            id: UUID().uuidString,
            chatType: .single,
            participants: participants,
            creationDate: Date(),
            lastMessageId: nil,
            lastMessageContent: nil,
            lastSeenTimeStamp: nil
        )

        do {
            try await chatsCollection.document(newChat.id).setData(newChat.toDictionary())
            self.currentChatId = newChat.id
            print("New chat created, -------- ✅----------- for \(participants)") // Debug: New chat created
        } catch {
            print("Failed to create chat: \(error.localizedDescription)") // Debug: Error creating chat
        }
    }
    //MARK: -isThereChat
    func isThereChat(for participants: [String]) async -> Bool {
        do {
            let querySnapshot = try await chatsCollection
                .whereField("participants", arrayContainsAny: participants)
                .getDocuments()

            for document in querySnapshot.documents {
                let chat = try document.data(as: FireChatModel.self)
                if Set(chat.participants) == Set(participants) {
                    print(" ----------------- Chat exists for participants------------") // Debug: Chat exists
                    return true
                }
            }
        } catch {
            print("Error checking chat existence: \(error.localizedDescription) \n") // Debug: Error checking chat existence
        }
        print("Chat does not exist for participants \n") //Debug: chat does not exist
        return false
    }
    //MARK: -deleteChat
    func deleteChat(for chatId: String) async {
        do {
            let messagesSnapshot = try await messagesCollection
                .whereField("chatId", isEqualTo: chatId)
                .getDocuments()

            for document in messagesSnapshot.documents {
                try await document.reference.delete()
            }

            try await chatsCollection.document(chatId).delete()

            print("Chat deleted, chat ID: \(chatId)")
        } catch {
            print("Failed to delete chat: \(error.localizedDescription)")
        }
    }

    //MARK: -fetchLastMessageDetails

    func fetchLastMessageDetails(for participants: [String]) async -> (content: String?, timestamp: Date?) {
        do {
            // First get the chatId for these exact participants
            guard let chatId = await getChatId(for: participants) else {
                return (nil, nil)
            }

            // Then fetch the chat document directly using this chatId
            let chatSnapshot = try await chatsCollection.document(chatId).getDocument()
            guard let chat = try? chatSnapshot.data(as: FireChatModel.self),
                  let lastMessageId = chat.lastMessageId else {
                return (nil, nil)
            }

            let messageSnapshot = try await messagesCollection.document(lastMessageId).getDocument()
            if let messageData = messageSnapshot.data(),
               let content = messageData["content"] as? String,
               let timestamp = messageData["timestamp"] as? Timestamp {
                print("Last message details fetched for chatId: \(chatId)")

                print("DEBUG: Last message details fetched - Content: \(content), Timestamp: \(timestamp)")

                return (content, timestamp.dateValue())
            }
        } catch {

            print("Error fetching last message details: \(error.localizedDescription)")
            print("\n")
        }
        print("No last message details found ")
        print("\n")
        return (nil, nil)
    }

}

