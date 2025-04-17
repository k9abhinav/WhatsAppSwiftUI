import SwiftUI
import FirebaseFirestore
import FirebaseStorage
@Observable
class FireUpdateViewModel {
    var allUpdates: [FireUpdateModel] = []
    var isLoading: Bool = false
    var error: String?

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var listeners: [ListenerRegistration] = []

    // Group updates by userId
    var updatesByUser: [String: [FireUpdateModel]] {
        Dictionary(grouping: allUpdates) { $0.userId }
    }

    // Get unique user IDs who have updates
    var usersWithUpdates: [String] {
        Array(updatesByUser.keys)
    }

    // MARK: - Setup Listeners for ALL updates
    func setupUpdatesListener() {
        // Remove any existing listeners
        removeListeners()

        isLoading = true

        // Listen for ALL updates that haven't expired
        let now = Date()
        let updatesRef = db.collection("updates")
            .whereField("expiresAt", isGreaterThan: now)
            .order(by: "expiresAt")

        let listener = updatesRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            self.isLoading = false

            if let error = error {
                self.error = "Error listening for updates: \(error.localizedDescription)"
                return
            }

            guard let documents = snapshot?.documents else { return }

            var validUpdates: [FireUpdateModel] = []

            for document in documents {
                do {
                    let update = try document.data(as: FireUpdateModel.self)
                    if update.expiresAt < Date() {
                        // Delete expired updates
                        Task {
                            await self.cleanupExpiredUpdate(update)
                        }
                    } else {
                        validUpdates.append(update)
                    }
                } catch {
                    print("❌ Error decoding update: \(error.localizedDescription)")
                }
            }

            self.allUpdates = validUpdates.sorted { $0.createdAt > $1.createdAt }
        }

        listeners.append(listener)
    }

    // Listen for updates from a specific user
    func setupUpdatesListener(for userId: String) {
        // Remove any existing listeners
        removeListeners()

        isLoading = true

        let now = Date()
        let updatesRef = db.collection("updates")
            .whereField("userId", isEqualTo: userId)
            .whereField("expiresAt", isGreaterThan: now)
            .order(by: "expiresAt")
            .order(by: "createdAt", descending: true)

        let listener = updatesRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            self.isLoading = false

            if let error = error {
                self.error = "Error listening for updates: \(error.localizedDescription)"
                return
            }

            guard let documents = snapshot?.documents else { return }

            var validUpdates: [FireUpdateModel] = []

            for document in documents {
                do {
                    let update = try document.data(as: FireUpdateModel.self)
                    if update.expiresAt < Date() {
                        // Delete expired updates
                        Task {
                            await self.cleanupExpiredUpdate(update)
                        }
                    } else {
                        validUpdates.append(update)
                    }
                } catch {
                    print("❌ Error decoding update: \(error.localizedDescription)")
                }
            }

            self.allUpdates = validUpdates.sorted { $0.createdAt > $1.createdAt }
        }

        listeners.append(listener)
    }

    private func removeListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }

    // Get updates for a specific user (non-listener version)
    func getUpdatesForUser(userId: String) -> [FireUpdateModel] {
        return allUpdates.filter { $0.userId == userId }.sorted { $0.createdAt < $1.createdAt }
    }

    // MARK: - Create Update
    func addTextUpdate(for userId: String, content: String) async {
        await addUpdate(for: userId, content: content, mediaType: .text, mediaData: nil)
    }

    func addImageUpdate(for userId: String, content: String, image: UIImage) async {
        if let imageData = image.jpegData(compressionQuality: 0.7) {
            await addUpdate(for: userId, content: content, mediaType: .image, mediaData: imageData)
        } else {
            self.error = "Failed to process image data"
        }
    }

    func addVideoUpdate(for userId: String, content: String, videoURL: URL) async {
        do {
            let videoData = try Data(contentsOf: videoURL)
            await addUpdate(for: userId, content: content, mediaType: .video, mediaData: videoData)
        } catch {
            self.error = "Failed to process video data: \(error.localizedDescription)"
        }
    }

    private func addUpdate(for userId: String, content: String, mediaType: FireUpdateModel.MediaType, mediaData: Data?) async {
        isLoading = true
        defer { isLoading = false }

        let now = Date()
        var mediaUrl: String? = nil

        // Upload media if needed
        if let mediaData = mediaData, mediaType != .text {
            do {
                mediaUrl = try await uploadMedia(userId: userId, mediaData: mediaData, mediaType: mediaType)
            } catch {
                self.error = "Failed to upload media: \(error.localizedDescription)"
                return
            }
        }

        // Create update
        let newUpdate = FireUpdateModel(
            id: UUID().uuidString,
            userId: userId,
            content: content,
            mediaType: mediaType,
            mediaUrl: mediaUrl,
            createdAt: now,
            expiresAt: Calendar.current.date(byAdding: .hour, value: 24, to: now)!
        )

        do {
            try db.collection("updates").document(newUpdate.id).setData(from: newUpdate)
        } catch {
            self.error = "Failed to add update: \(error.localizedDescription)"

            // Clean up media if update creation failed
            if let mediaUrl = mediaUrl {
                Task {
                    await deleteMediaFromStorage(mediaUrl: mediaUrl)
                }
            }
        }
    }

    // MARK: - Media Management
    private func uploadMedia(userId: String, mediaData: Data, mediaType: FireUpdateModel.MediaType) async throws -> String {
        let fileExtension = mediaType == .image ? "jpg" : "mp4"
        let filename = "updates/\(userId)/\(UUID().uuidString).\(fileExtension)"
        let storageRef = storage.reference().child(filename)

        let metadata = StorageMetadata()
        metadata.contentType = mediaType == .image ? "image/jpeg" : "video/mp4"

        let _ = try await storageRef.putDataAsync(mediaData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }

    private func deleteMediaFromStorage(mediaUrl: String) async {
        guard let url = URL(string: mediaUrl),
              url.host?.contains("firebasestorage") == true,
              let path = url.path.components(separatedBy: "o/").last?.removingPercentEncoding else {
            return
        }

        do {
            try await storage.reference().child(path).delete()
        } catch {
            print("❌ Error deleting media: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete and Cleanup
    func deleteUpdate(for updateId: String) async {
        let updateRef = db.collection("updates").document(updateId)

        do {
            // Get the update first to check if it has media
            let document = try await updateRef.getDocument()
            if let update = try document.data(as: FireUpdateModel?.self),
               let mediaUrl = update.mediaUrl {
                await deleteMediaFromStorage(mediaUrl: mediaUrl)
            }

            // Then delete the document
            try await updateRef.delete()
        } catch {
            self.error = "Error deleting update: \(error.localizedDescription)"
        }
    }

    private func cleanupExpiredUpdate(_ update: FireUpdateModel) async {
        // Delete media if it exists
        if let mediaUrl = update.mediaUrl {
            await deleteMediaFromStorage(mediaUrl: mediaUrl)
        }

        // Delete the document
        do {
            try await db.collection("updates").document(update.id).delete()
        } catch {
            print("❌ Error cleaning up expired update: \(error.localizedDescription)")
        }
    }

    // MARK: - Background Cleanup
    func scheduleCleanupTask() {
        // This would ideally be handled by a Firebase Cloud Function or other server-side process
        // But for client-side, we can set up a periodic check
        // In a real app, you would use a more robust solution like Firebase Cloud Functions
        // For now we'll implement a simple client-side check
        Task {
            while true {
                // Check every hour
                try? await Task.sleep(nanoseconds: 60 * 60 * 1_000_000_000)

                for update in allUpdates {
                    if update.isExpired {
                        await cleanupExpiredUpdate(update)
                    }
                }
            }
        }
    }

    deinit {
        removeListeners()
    }
}
