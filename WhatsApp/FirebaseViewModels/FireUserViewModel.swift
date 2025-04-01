
import SwiftUI
import FirebaseFirestore
import FirebaseStorage

@MainActor
@Observable
final class FireUserViewModel {
    // MARK: - Properties
    var users: [FireUserModel] = [] // Stores users who have chats with the logged-in user
    var allUsers: [FireUserModel] = [] // Stores all users fetched from Firestore

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
        print("\n")
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
        print("\n")
        print("Users listener SETUP complete") // Debug: Listener setup
        print("\n")
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
            print("\n")
            print("Failed to fetch all users: \(error.localizedDescription)") // Debug: Error fetching all users
        }
    }

    func fetchUsersWithChats(loggedInUserId: String) async {
        do {
            let snapshot = try await chatsCollection.getDocuments()
            let chatDocuments = snapshot.documents.compactMap { try? $0.data(as: FireChatModel.self) }

            var userChatTimestamps: [String: Date] = [:]  // ✅ Dictionary avoids duplicates

            for chat in chatDocuments where chat.participants.contains(loggedInUserId) {
                let lastMessageTimestamp = chat.lastSeenTimeStamp ?? Date.distantPast

                for participant in chat.participants {
                    userChatTimestamps[participant] = lastMessageTimestamp
                }
            }

            guard !userChatTimestamps.isEmpty else {
                print("\n")
                print("No users found with chats")
                return
            }

            // ✅ Sort by last message timestamp (latest first)
            let sortedUserIds = userChatTimestamps
                .sorted { $0.value > $1.value }
                .map { $0.key }

            self.users = sortedUserIds.compactMap { userId in
                allUsers.first { $0.id == userId }
            }
            print("\n")
            print("Sorted User IDs: \(sortedUserIds)")
            print("\n")
            print("Fetched users with chats, count: \(self.users.count)")

        } catch {
            print("Failed to fetch users with chats: \(error.localizedDescription)")
        }
    }




    // MARK: - Profile Image Handling
    func changeProfileImage(userId: String, image: UIImage) async {
        if let imageUrl = await uploadProfileImage(userId: userId, image: image) {
            await updateProfileImage(userId: userId, imageUrl: imageUrl)
        }
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
            print("\n")
            print("Image uploaded successfully, URL: \(url.absoluteString)") // Debug: Image uploaded
            print("\n")
            return url.absoluteString
        } catch {
            print("\n")
            print("Error uploading image: \(error.localizedDescription)") // Debug: Error uploading image
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
        print("\n")
        print("Failed to convert image to PNG or JPEG") // Debug: Image conversion failed
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
                print("\n")
                print("Error updating field \(fieldName): \(error.localizedDescription)") // Debug: Error updating field
            } else {
                print("\n")
                print("Field \(fieldName) updated successfully (completion handler)") // Debug: Field updated
            }
            completion(error)
        }
    }

    private func updateUserField<T>(userId: String, fieldName: String, value: T) async {
        do {
            try await getUserRef(userId: userId).updateData([fieldName: value])
            print("\(fieldName) updated successfully (async)") // Debug: Field updated
        } catch {
            print("Error updating \(fieldName): \(error.localizedDescription)") // Debug: Error updating field
        }
    }

    private func getUserRef(userId: String) -> DocumentReference {
        return usersCollection.document(userId)
    }
}

