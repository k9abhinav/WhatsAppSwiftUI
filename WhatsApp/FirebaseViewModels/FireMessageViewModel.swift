import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import UniformTypeIdentifiers
@MainActor
@Observable
final class FireMessageViewModel {
    private let storageRef = Storage.storage().reference()
    private let db = Firestore.firestore()
    private let chatsCollection: CollectionReference
    private let messagesCollection: CollectionReference
    private let usersCollection: CollectionReference
    private var messageListener: ListenerRegistration?
    var messages: [FireMessageModel] = []

    init() {
        self.chatsCollection = db.collection("chats")
        self.messagesCollection = db.collection("messages")
        self.usersCollection = db.collection("users")
        print("FireMessageViewModel initialized") // Debug: Initialization
    }

    func setupMessageListener(for chatId: String) {
        messageListener?.remove() // Remove previous listener if any
        messageListener = messagesCollection
            .whereField("chatId", isEqualTo: chatId)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents, error == nil else {
                    print("\n")
                    print("Error fetching messages: \(error?.localizedDescription ?? "Unknown error")") // Debug: Error fetching messages
                    return
                }
                self.messages = documents.compactMap { try? $0.data(as: FireMessageModel.self) }
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
        content: String = "",
        currentUserId: String,
        otherUserId: String,
        imageData: UIImage,
        replyToMessageId: String? = nil,
        isForwarded: Bool = false
    ) async {
        do {
            let chatSnapshot = try await chatsCollection.document(chatId).getDocument()
            guard let chatData = chatSnapshot.data(),
                  let participants = chatData["participants"] as? [String],
                  participants.contains(currentUserId),
                  participants.contains(otherUserId) else {
                print("Error: Invalid chat participants or chat document.")
                return
            }

            let newMessageId = UUID().uuidString

            // 🔹 Upload the image first and get the URL
            let mediaUploadResult = await uploadMediaToFirebaseStorage(mediaData: imageData, chatID: chatId, messageId: newMessageId)

            switch mediaUploadResult {
            case .success(let mediaUrl):
                print("✅ Media upload successful: \(mediaUrl)")

                let newMessage = FireMessageModel(
                    id: newMessageId,
                    chatId: chatId,
                    messageType: .image,
                    content: content,
                    senderUserId: currentUserId,
                    receiverUserId: otherUserId,
                    timestamp: Date(),
                    replyToMessageId: replyToMessageId,
                    isForwarded: isForwarded,
                    imageUrl: mediaUrl // ✅ Now, imageUrl is correctly set
                )

                try messagesCollection.document(newMessage.id).setData(from: newMessage)

                let batch = chatsCollection.firestore.batch()
                let chatDocRef = chatsCollection.document(chatId)
                batch.updateData([
                    "lastMessageId": newMessage.id,
                    "lastSeenTimeStamp": newMessage.timestamp,
                    "lastMessageContent": "📷 Photo"
                ], forDocument: chatDocRef)

                try await batch.commit()
                print("✅ Image message sent successfully. Message ID: \(newMessage.id)")

            case .failure(let error):
                print("❌ Error uploading media: \(error)")
            }
        }
        catch {
            print("❌ Error sending message: \(error)")
        }
    }


    func uploadMediaToFirebaseStorage(mediaData: UIImage, chatID: String, messageId: String) async -> Result<String, Error> {
        let storageRef = Storage.storage().reference()

        var imageData: Data?
        let fileExtension: String
        let contentType: String

        if let pngData = mediaData.pngData() {
            imageData = pngData
            fileExtension = "png"
            contentType = "image/png"
        } else if let jpegData = mediaData.jpegData(compressionQuality: 0.8) {
            imageData = jpegData
            fileExtension = "jpg"
            contentType = "image/jpeg"
        } else {
            return .failure(NSError(domain: "Image Conversion Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data."]))
        }

        guard let finalData = imageData else {
            return .failure(NSError(domain: "Image Data Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "No valid image data available."]))
        }

        let imageRef = storageRef.child("chat_images_of_\(chatID)/\(messageId).\(fileExtension)")
        let metadata = StorageMetadata()
        metadata.contentType = contentType

        do {
            _ = try await imageRef.putDataAsync(finalData, metadata: metadata)
            let url = try await imageRef.downloadURL()
            return .success(url.absoluteString)
        } catch {
            return .failure(error)
        }
    }

}
