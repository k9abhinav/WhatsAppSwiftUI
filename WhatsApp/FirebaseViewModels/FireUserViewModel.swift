
import SwiftUI
import FirebaseFirestore
import FirebaseStorage

@MainActor
@Observable
final class FireUserViewModel {
    // MARK: - Properties
    var users: [FireUserModel] = [] // Stores users who have chats with the logged-in user
    var allUsers: [FireUserModel] = [] // Stores all users fetched from Firestore
    var triggerProfilePicUpdated = false
    // MARK: - Firebase References
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    private let usersCollection: CollectionReference
    private let chatsCollection: CollectionReference
    private var listenerRegistration: ListenerRegistration?

    // MARK: - Init
    init() {
        usersCollection = db.collection("users")
        chatsCollection = db.collection("chats")
        print("FireUserViewModel initialized") // Debug: Initialization
        print("\n")
    }

    // MARK: - Listeners
    func setupUsersListener() {
        listenerRegistration = usersCollection.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self, let documents = snapshot?.documents, error == nil else {
                print("Error fetching users: \(error?.localizedDescription ?? "Unknown error")") // Debug: Error fetching users
                return
            }

            self.allUsers = documents.compactMap {  try? $0.data(as: FireUserModel.self)  }
            print("\n")
            print("Users listener triggered, allUsers count: \(self.allUsers.count)") // Debug: Listener triggered
            print("\n")
        }
        setupChatsListener()
    }
    private func setupChatsListener() {
        chatsCollection.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self, let documents = snapshot?.documents, error == nil else {
                print("Error fetching chats: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let chatDocuments = documents.compactMap { try? $0.data(as: FireChatModel.self) }
            var userChatTimestamps: [String: Date] = [:]

            for chat in chatDocuments {
                let lastMessageTimestamp = chat.lastSeenTimeStamp ?? Date.distantPast
                for participant in chat.participants {
                    userChatTimestamps[participant] = lastMessageTimestamp
                }
            }

            // ✅ Sort users based on latest message
            let sortedUserIds = userChatTimestamps.sorted { $0.value > $1.value }.map { $0.key }
            self.users = sortedUserIds.compactMap { userId in
                self.allUsers.first { $0.id == userId }
            }

            print("Chats listener triggered, updated users count: \(self.users.count)")
        }
    }

    func removeListener() {
        listenerRegistration?.remove()
        print("\n")
        print("Users listener removed") // Debug: Listener removed
    }

    // MARK: - User Fetching
    func fetchAllUsersContacts() async {
        do {
            let snapshot = try await usersCollection.getDocuments()
            self.allUsers = snapshot.documents.compactMap { try? $0.data(as: FireUserModel.self) }
            print("\n")
            print("Fetched all users, count: \(self.allUsers.count)") // Debug: Fetched all users
        } catch {
            print("Failed to fetch all users: \(error.localizedDescription)") // Debug: Error fetching all users
        }
    }

    func fetchUsersWithChats(loggedInUserId: String) async {
        do {
            let userChatTimestamps = try await fetchUserChatTimestamps(loggedInUserId: loggedInUserId)
            await sortUsersByLastMessage(userChatTimestamps)
        } catch {
            print("Failed to fetch users with chats: \(error.localizedDescription)")
        }
    }

    // 🔹 Fetch chat timestamps for all participants
    private func fetchUserChatTimestamps(loggedInUserId: String) async throws -> [String: Date] {
        let snapshot = try await chatsCollection.getDocuments()
        let chatDocuments = snapshot.documents.compactMap { try? $0.data(as: FireChatModel.self) }

        var userChatTimestamps: [String: Date] = [:]

        for chat in chatDocuments where chat.participants.contains(loggedInUserId) {
            let lastMessageTimestamp = chat.lastSeenTimeStamp ?? Date.distantPast

            for participant in chat.participants {
                userChatTimestamps[participant] = lastMessageTimestamp
            }
        }

        print("Fetched chat timestamps for \(userChatTimestamps.count) users")
        return userChatTimestamps
    }

    // 🔹 Sort users by last message timestamp
    private func sortUsersByLastMessage(_ userChatTimestamps: [String: Date]) async {
        guard !userChatTimestamps.isEmpty else {
            print("No users found with chats")
            print("\n")
            return
        }

        let sortedUserIds = userChatTimestamps
            .sorted { $0.value > $1.value }
            .map { $0.key }

        self.users = sortedUserIds.compactMap { userId in
            allUsers.first { $0.id == userId }
        }

        print("Sorted users with chats, count: \(self.users.count)")
        print("\n")
    }



    // MARK: - Profile Image Handling
    func changeProfileImage(userId: String, image: UIImage) async -> String? {
        if let imageUrl = await uploadProfileImage(userId: userId, image: image) {
            await updateProfileImage(userId: userId, imageUrl: imageUrl)
            await AuthViewModel().loadCurrentUser()
            self.triggerProfilePicUpdated = true
            print("Triggered Profile Pic Updated ✅...........................")
            return imageUrl // ✅ Now returns the uploaded image URL
        }
        return nil
    }


    func uploadProfileImage(userId: String, image: UIImage) async -> String? {
        guard let (imageData, fileExtension) = getImageDataAndExtension(image: image) else {
            print("Failed to get image data and extension") // Debug: Failed to get image data
            return nil
        }

        let imageRef = storage.child("profile_images/\(userId).\(fileExtension)")

        do {
            let _ = try await imageRef.putDataAsync(imageData)
            let url = try await imageRef.downloadURL()
            print("Image uploaded successfully, URL: \(url.absoluteString)")
            print("\n")
            return url.absoluteString
        } catch {
            print("Error uploading image: \(error.localizedDescription)")
            print("\n")
            return nil
        }
    }

    private func getImageDataAndExtension(image: UIImage) -> (Data, String)? {
        if let pngData = image.pngData() {
            return (pngData, "png")
        } else if let jpegData = image.jpegData(compressionQuality: 0.5) {
            return (jpegData, "jpg")
        }
        print("Failed to convert image to PNG or JPEG \n")

        return nil
    }

    func updateProfileImage(userId: String, imageUrl: String) async {
        await updateUserField(userId: userId, fieldName: "imageUrl", value: imageUrl)
    }

    // MARK: - User Updates
    func updateUserName(userId: String, newName: String, completion: @escaping (Error?) -> Void) {
        updateUserField(userId: userId, fieldName: "name", value: newName, completion: completion)
    }

    func updateUserPhone(userId: String, newPhone: String, completion: @escaping (Error?) -> Void) {
        updateUserField(userId: userId, fieldName: "phoneNumber", value: newPhone, completion: completion) // Changed to phoneNumber
    }

    func updateUserStatus(userId: String, newStatus: String, completion: @escaping (Error?) -> Void) {
        updateUserField(userId: userId, fieldName: "aboutInfo", value: newStatus, completion: completion)
    }

    func updateUserOnlineStatus(userId: String, newStatus: Bool, completion: @escaping (Error?) -> Void) {
        updateUserField(userId: userId, fieldName: "onlineStatus", value: newStatus, completion: completion)
    }

    // MARK: - Helper Methods
    private func updateUserField(userId: String, fieldName: String, value: Any, completion: @escaping (Error?) -> Void) {
        getUserRef(userId: userId).updateData([fieldName: value]) { error in
            if let error = error {
                print("Error updating field \(fieldName): \(error.localizedDescription) \n")
            } else {
                print("Field \(fieldName) updated successfully (completion handler) \n")
            }
            completion(error)
        }
    }

    private func updateUserField<T>(userId: String, fieldName: String, value: T) async {
        do {
            try await getUserRef(userId: userId).updateData([fieldName: value])
            print("\(fieldName) updated successfully (async)")
        } catch {
            print("Error updating \(fieldName): \(error.localizedDescription)")
        }
    }

    private func getUserRef(userId: String) -> DocumentReference {
        return usersCollection.document(userId)
    }
}

