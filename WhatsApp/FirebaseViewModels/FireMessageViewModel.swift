import SwiftUI
import FirebaseFirestore
import FirebaseStorage
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
                    print("\n")
                    print("Error fetching messages: \(error?.localizedDescription ?? "Unknown error")") // Debug: Error fetching messages
                    return
                }
                self.messages = Array(documents.compactMap { try? $0.data(as: FireMessageModel.self) })
                print("\n")
                print("Messages listener triggered for chatId: \(chatId), message count: \(self.messages.count)") // Debug: Listener triggered
                print("\n")
            }
        print("\n")
        print("Messages listener setup for chatId: \(chatId)") // Debug: Listener setup
        print("\n")
    }

    func removeMessageListener() {
        messageListener?.remove()
        print("\n")
        print("Messages listener removed") // Debug: Listener removed
    }

    func fetchAllMessages(for chatId: String) async {
        do {
            let snapshot = try await messagesCollection
                .whereField("chatId", isEqualTo: chatId)
                .order(by: "timestamp", descending: false)
                .getDocuments()

            self.messages = snapshot.documents.compactMap { try? $0.data(as: FireMessageModel.self) }
            print("\n")
            print("Fetched all messages for chatId: \(chatId), message count: \(self.messages.count)")
            print("\n")// Debug: Fetched all messages
        } catch {
            print("\n")
            print("Failed to fetch messages: \(error.localizedDescription)") // Debug: Error fetching messages
        }
    }

    func sendTextMessage(
        chatId: String,
        currentUserId: String,
        otherUserId: String,
        content: String
    ) async {
        let trimmedContent = content.trimmingCharacters(in: .whitespaces)
        guard !trimmedContent.isEmpty else {
            print("Error: Message content is empty.")
            return
        }

        do {
            let chatSnapshot = try await chatsCollection.document(chatId).getDocument()
            guard let chatData = chatSnapshot.data(),
                  let participants = chatData["participants"] as? [String],
                  participants.contains(currentUserId),
                  participants.contains(otherUserId) else {
                print("Error: Invalid chat participants or chat document.")
                return
            }

            let newMessage = FireMessageModel(
                id: UUID().uuidString,
                chatId: chatId,
                messageType: .text,
                content: trimmedContent,
                senderUserId: currentUserId,
                receiverUserId: otherUserId,
                timestamp: Date(),
                replyToMessageId: nil,
                isForwarded: false
            )

            try messagesCollection.document(newMessage.id).setData(from: newMessage)

            let batch = chatsCollection.firestore.batch()

            let chatDocRef = chatsCollection.document(chatId)
            batch.updateData(["lastMessageId": newMessage.id,
                                 "lastSeenTimeStamp": newMessage.timestamp,
                                 "lastMessageContent": trimmedContent], forDocument: chatDocRef)

            try await batch.commit()
            print("\n")
            print("Message sent successfully. Message ID: \(newMessage.id)")
            print("\n")

        } catch {
            print("\n")
            print("Error sending message: \(error)")
            print("\n")
        }
    }

    func deleteTextMessage(for messageId: String) async {
        do {
            try await messagesCollection.document(messageId).delete()
            print("\n")
            print("Message deleted successfully, messageId: \(messageId)") // Debug: Message deleted
            print("\n")
        } catch {
            print("Failed to delete message: \(error.localizedDescription)") // Debug: Error deleting message
        }
    }

    func sendImageMessage(
        chatId: String,
        currentUserId: String,
        otherUserId: String,
        imageData: Data
    ) async {
        uploadImageToFirebaseStorage(imageData: imageData) { result in
            switch result {
            case .success(let imageURL):
                Task {
                    await self.sendMessageWithImage(chatId: chatId, currentUserId: currentUserId, otherUserId: otherUserId, imageURL: imageURL)
                }
            case .failure(let error):
                print("Error uploading image: \(error.localizedDescription)")
            }
        }
    }

    private func sendMessageWithImage(
        chatId: String,
        currentUserId: String,
        otherUserId: String,
        imageURL: String
    ) async {
        do {
            let newMessage = FireMessageModel(
                id: UUID().uuidString,
                chatId: chatId,
                messageType: .image,
                content: imageURL,
                senderUserId: currentUserId,
                receiverUserId: otherUserId,
                timestamp: Date(),
                replyToMessageId: nil,
                isForwarded: false
            )

            try messagesCollection.document(newMessage.id).setData(from: newMessage)

            let batch = chatsCollection.firestore.batch()
            let chatDocRef = chatsCollection.document(chatId)
            batch.updateData([
                "lastMessageId": newMessage.id,
                "lastSeenTimeStamp": newMessage.timestamp,
                "lastMessageContent": "[Image]"
            ], forDocument: chatDocRef)

            try await batch.commit()
            print("Image message sent successfully. Message ID: \(newMessage.id)")

        } catch {
            print("Error sending image message: \(error)")
        }
    }

    func uploadImageToFirebaseStorage(imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("chat_images/\(UUID().uuidString).jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        imageRef.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            imageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                if let urlString = url?.absoluteString {
                    completion(.success(urlString))
                }
            }
        }
    }

}
