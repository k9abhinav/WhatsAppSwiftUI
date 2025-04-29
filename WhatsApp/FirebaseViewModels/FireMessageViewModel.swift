import SwiftUI
import FirebaseFirestore
import FirebaseStorage

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
        print("FireMessageViewModel initialized ----------- ✅ ----------") // Debug: Initialization
    }
    deinit {
        messageListener?.remove()
        print("FireMessageViewModel deinitialized ----------- ❌ ---------- ")
    }

    func setupMessageListener(for chatId: String) {
        messageListener?.remove() // Remove previous listener if any
        messageListener = messagesCollection
            .whereField("chatId", isEqualTo: chatId)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let documents = snapshot?.documents, error == nil else {

                    print("Error fetching messages: \(error?.localizedDescription ?? "Unknown error -----------  ❌ ---------- ")")
                    return
                }
                self.messages = documents.compactMap { try? $0.data(as: FireMessageModel.self) }

                print("Messages listener triggered for chatId: \(chatId), message count: \(self.messages.count)")
            }
        print("Messages listener setup for chatId ----------- ✅ ---------- : \(chatId)")

    }

    func removeMessageListener() {
        messageListener?.remove()

        print("Messages listener removed -----------  ❌ ---------- ")
    }
    
    func sendTextMessage(
        chatId: String,
        currentUserId: String,
        otherUserId: String,
        content: String
    ) async {
        let trimmedContent = content.trimmingCharacters(in: .whitespaces)
        guard !trimmedContent.isEmpty else {
            print("Error: Message content is empty. -----------  ❌ ---------- ")
            return
        }

        do {
            let chatSnapshot = try await chatsCollection.document(chatId).getDocument()
            guard let chatData = chatSnapshot.data(),
                  let participants = chatData["participants"] as? [String],
                  participants.contains(currentUserId),
                  participants.contains(otherUserId) else {
                print("Error: Invalid chat participants or chat document. -----------  ❌ ---------- ")
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
                isReply: false ,
                isForwarded: false,
                isSeen: nil
            )
            try messagesCollection.document(newMessage.id).setData(from: newMessage)
            let batch = chatsCollection.firestore.batch()
            let chatDocRef = chatsCollection.document(chatId)
            batch.updateData(
                ["lastMessageId": newMessage.id,
                 "lastSeenTimeStamp": newMessage.timestamp,
                 "lastMessageContent": trimmedContent
                ],
                forDocument: chatDocRef
            )
            try await batch.commit()
            print("Message sent successfully. ----------- ✅ ---------- ")
        } catch {
            print("Error sending message -----------  ❌ ---------- : \(error)")

        }
    }
    func markMessageAsSeen(messageId: String, chatId: String) async {
        do {
            let messageDocRef = messagesCollection.document(messageId)
            let chatDocRef = chatsCollection.document(chatId)

            // Check if the message exists
            let messageSnapshot = try await messageDocRef.getDocument()
            guard messageSnapshot.exists else {
                print("Error: Message does not exist. ----------- ❌ ---------- ")
                return
            }

            // Update isSeen to true for the message
            try await messageDocRef.updateData(["isSeen": true])

            // Optionally update the chat document to reflect the last seen message
            try await chatDocRef.updateData(["lastSeenMessageId": messageId])

            print("Message marked as seen successfully. ----------- ✅ ---------- ")
        } catch {
            print("Error marking message as seen ----------- ❌ ---------- : \(error)")
        }
    }

    func deleteMessage(for messageId: String) async {
        do {
            let messageSnapshot = try await messagesCollection.document(messageId).getDocument()
            guard let messageData = messageSnapshot.data() else {
                print("Failed to retrieve message data -------- ❌ ---------- ")
                return
            }
            if let imageUrl = messageData["imageUrl"] as? String {

                let storageRef = Storage.storage().reference(forURL: imageUrl)
                do {
                    try await storageRef.delete()
                    print("Image deleted successfully ----------- ✅ ---------- ")
                } catch {
                    print("Failed to delete image from storage ----- ❌ ---------- : \(error.localizedDescription)")
                }

                try await messagesCollection.document(messageId).updateData([
                    "imageUrl": FieldValue.delete(),
                    "messageType": "text",
                    "content": "You deleted this message"
                ])
                print("Message updated successfully ----------- ✅ ---------- ")
            }

            else if let voiceUrl = messageData["voiceUrl"] as? String {
                let storageRef = Storage.storage().reference(forURL: voiceUrl)
                do {
                    try await storageRef.delete()
                    print("Voice audio deleted successfully ----------- ✅ ---------- ")
                } catch {
                    print("Failed to delete image from storage ----- ❌ ---------- : \(error.localizedDescription)")
                }

                try await messagesCollection.document(messageId).updateData([
                    "voiceUrl": FieldValue.delete(),
                    "voiceDuration":FieldValue.delete(),
                    "messageType": "text",
                    "content": "You deleted this message"
                ])
                print("Message updated successfully ----------- ✅ ---------- ")
            }

            else {
                try await messagesCollection.document(messageId).updateData(["content": "You deleted this message"])
                print("Message content updated successfully ----------- ✅ ---------- ")
            }
        } catch {
            print("Failed to delete message ----- ❌ ---------- : \(error.localizedDescription)") // Debug: Error deleting message
        }
    }

    func sendVoiceMessage(
            chatId: String,
            currentUserId: String,
            otherUserId: String,
            audioFileURL: URL,
            duration: TimeInterval
        ) async {
            do {
                let chatSnapshot = try await chatsCollection.document(chatId).getDocument()
                guard let chatData = chatSnapshot.data(),
                      let participants = chatData["participants"] as? [String],
                      participants.contains(currentUserId),
                      participants.contains(otherUserId) else {
                    print("Error: Invalid chat participants or chat document. ----------- ❌ ----------")
                    return
                }

                let newMessageId = UUID().uuidString

                // Upload the voice recording to Firebase Storage
                let audioUploadResult = await uploadAudioToFirebaseStorage(audioFileURL: audioFileURL, chatID: chatId, messageId: newMessageId)

                switch audioUploadResult {
                case .success(let audioUrl):
                    print("Audio upload successful. ----------- ✅ ----------")

                    let newMessage = FireMessageModel(
                        id: newMessageId,
                        chatId: chatId,
                        messageType: .voice,
                        content: "Voice Message (\(Int(duration))s)",
                        senderUserId: currentUserId,
                        receiverUserId: otherUserId,
                        timestamp: Date(),
                        replyToMessageId: nil,
                        isReply: false,
                        isForwarded: false,
                        isSeen: nil,
                        voiceUrl: audioUrl,
                        voiceDuration: duration
                    )

                    try messagesCollection.document(newMessage.id).setData(from: newMessage)

                    let batch = chatsCollection.firestore.batch()
                    let chatDocRef = chatsCollection.document(chatId)
                    batch.updateData([
                        "lastMessageId": newMessage.id,
                        "lastSeenTimeStamp": newMessage.timestamp,
                        "lastMessageContent": "🎙️ Voice Message"
                    ], forDocument: chatDocRef)

                    try await batch.commit()
                    print("Voice message sent successfully. ----------- ✅ ----------")

                case .failure(let error):
                    print("Error uploading audio: ----------- ❌ ---------- \(error)")
                }
            } catch {
                print("Error sending voice message: ----------- ❌ ---------- \(error)")
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
        // Create a temporary message ID
        let newMessageId = UUID().uuidString

        // Create and add local message immediately
        let localMessage = FireMessageModel(
            id: newMessageId,
            chatId: chatId,
            messageType: .image,
            content: content,
            senderUserId: currentUserId,
            receiverUserId: otherUserId,
            timestamp: Date(),
            replyToMessageId: replyToMessageId,
            isReply: false,
            isForwarded: isForwarded,
            imageUrl: nil, // No URL yet
            isSeen: nil,
            localImage: imageData, // Store the local image
            isUploading: true // Mark as uploading
        )

        // Add to local messages array immediately
        DispatchQueue.main.async {
            self.messages.append(localMessage)
        }

        // Continue with upload process
        do {
            let chatSnapshot = try await chatsCollection.document(chatId).getDocument()
            guard let chatData = chatSnapshot.data(),
                  let participants = chatData["participants"] as? [String],
                  participants.contains(currentUserId),
                  participants.contains(otherUserId) else {
                print("Error: Invalid chat participants or chat document.")
                return
            }

            let mediaUploadResult = await uploadMediaToFirebaseStorage(mediaData: imageData, chatID: chatId, messageId: newMessageId)
            switch mediaUploadResult {
            case .success(let mediaUrl):
                // Update Firestore with the complete message
                let newMessage = FireMessageModel(
                    id: newMessageId,
                    chatId: chatId,
                    messageType: .image,
                    content: content,
                    senderUserId: currentUserId,
                    receiverUserId: otherUserId,
                    timestamp: Date(),
                    replyToMessageId: replyToMessageId,
                    isReply: false,
                    isForwarded: isForwarded,
                    imageUrl: mediaUrl,
                    isSeen: nil
                )

                try messagesCollection.document(newMessage.id).setData(from: newMessage)

                let batch = chatsCollection.firestore.batch()
                let chatDocRef = chatsCollection.document(chatId)
                batch.updateData([
                    "lastMessageId": newMessage.id,
                    "lastSeenTimeStamp": newMessage.timestamp,
                    "lastMessageContent": "📸 Photo"
                ], forDocument: chatDocRef)

                try await batch.commit()
                print("✅ Image message sent successfully. ----------- ✅ ---------- ")

                // No need to update local message as the listener will handle it

            case .failure(let error):
                print("❌ Error uploading media: \(error)")

                // Update local message to show error
                DispatchQueue.main.async {
                    if let index = self.messages.firstIndex(where: { $0.id == newMessageId }) {
                        self.messages[index].isUploading = false
                        // Optionally add an error indicator
                    }
                }
            }
        } catch {
            print("❌ Error sending message: \(error)")

            // Update local message to show error
            DispatchQueue.main.async {
                if let index = self.messages.firstIndex(where: { $0.id == newMessageId }) {
                    self.messages[index].isUploading = false
                    // Optionally add an error indicator
                }
            }
        }
    }
    func sendVideoMessage(
        chatId: String,
        content: String = "",
        currentUserId: String,
        otherUserId: String,
        videoData: Data,
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

            // 🔹 Upload the video first and get the URL
            let mediaUploadResult = await uploadVideoToFirebaseStorage(videoData: videoData, chatID: chatId, messageId: newMessageId)

            switch mediaUploadResult {
            case .success(let mediaUrl):
                print("---------✅------------- Media upload successful.")

                let newMessage = FireMessageModel(
                    id: newMessageId,
                    chatId: chatId,
                    messageType: .video,
                    content: content,
                    senderUserId: currentUserId,
                    receiverUserId: otherUserId,
                    timestamp: Date(),
                    replyToMessageId: replyToMessageId,
                    isReply: false,
                    isForwarded: isForwarded,
                    isSeen: nil,
                    videoUrl: mediaUrl
                )

                try messagesCollection.document(newMessage.id).setData(from: newMessage)

                let batch = chatsCollection.firestore.batch()
                let chatDocRef = chatsCollection.document(chatId)
                batch.updateData([
                    "lastMessageId": newMessage.id,
                    "lastSeenTimeStamp": newMessage.timestamp,
                    "lastMessageContent": "🎥 Video"
                ], forDocument: chatDocRef)

                try await batch.commit()
                print("✅ Video message sent successfully. ----------- ✅ ---------- ")

            case .failure(let error):
                print("❌ Error uploading media: \(error)")
            }
        }
        catch {
            print("❌ Error sending message: \(error)")
        }
    }


    func uploadAudioToFirebaseStorage(audioFileURL: URL, chatID: String, messageId: String) async -> Result<String, Error> {
            let storageRef = Storage.storage().reference()

            do {
                let audioData = try Data(contentsOf: audioFileURL)
                let audioRef = storageRef.child("chat_voice_messages_of_\(chatID)/\(messageId).m4a")

                let metadata = StorageMetadata()
                metadata.contentType = "audio/m4a"

                _ = try await audioRef.putDataAsync(audioData, metadata: metadata)
                let url = try await audioRef.downloadURL()
                return .success(url.absoluteString)
            } catch {
                return .failure(error)
            }
        }
    func uploadVideoToFirebaseStorage(videoData: Data, chatID: String, messageId: String) async -> Result<String, Error> {
        let storageRef = Storage.storage().reference()

        let fileExtension = "mp4" // Video format
        let contentType = "video/mp4"

        let videoRef = storageRef.child("chat_videos_of_\(chatID)/\(messageId).\(fileExtension)")
        let metadata = StorageMetadata()
        metadata.contentType = contentType

        do {
            // Upload the video data
            _ = try await videoRef.putDataAsync(videoData, metadata: metadata)

            // Retrieve the download URL
            let url = try await videoRef.downloadURL()
            return .success(url.absoluteString)
        } catch {
            return .failure(error)
        }
    }

    func uploadMediaToFirebaseStorage(mediaData: UIImage, chatID: String, messageId: String) async -> Result<String, Error> {
        let storageRef = Storage.storage().reference()

        // Define target file size (below 10MB)
        let targetFileSize: Int = 10 * 1024 * 1024
        var imageData: Data?
        let fileExtension: String
        let contentType: String

        // Dynamically adjust compression
        func compressedData(from image: UIImage) -> Data? {
            var compressionQuality: CGFloat = 1.0
            var compressedData: Data?

            repeat {
                compressedData = image.jpegData(compressionQuality: compressionQuality)
                compressionQuality -= 0.1
            } while (compressedData?.count ?? 0) > targetFileSize && compressionQuality > 0.1

            return compressedData
        }

        if let jpegData = compressedData(from: mediaData) {
            imageData = jpegData
            fileExtension = "jpg"
            contentType = "image/jpeg"
        } else {
            return .failure(NSError(domain: "Image Compression Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image within limits."]))
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
