import SwiftUI
import FirebaseFirestore
import FirebaseStorage

@MainActor
@Observable
final class FireUserViewModel {
    // MARK: - Properties
    var users: [FireUserModel] = []

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
    }

    // MARK: - Listeners
    func setupUsersListener() {
        removeListener()

        // Create a new listener
        listenerRegistration = usersCollection.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("Error listening for user updates: \(error.localizedDescription)")
                return
            }

            guard let snapshot = snapshot else { return }

            Task {
                await self.handleUsersSnapshot(snapshot)
            }
        }
    }

    private func handleUsersSnapshot(_ snapshot: QuerySnapshot) async {
        var fetchedUsers: [FireUserModel] = []

        for doc in snapshot.documents {
            do {
                let user = try doc.data(as: FireUserModel.self)
                fetchedUsers.append(user)
            } catch {
                print("Error decoding document \(doc.documentID): \(error)")
            }
        }

        self.users = fetchedUsers
        print("Users updated. Count: \(users.count)")
    }

    private func removeListener() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }

    // MARK: - User Fetching
    func fetchUsers() async {
        do {
            let snapshot = try await usersCollection.getDocuments()
            print("Document count: \(snapshot.documents.count)")

            var fetchedUsers: [FireUserModel] = []
            for doc in snapshot.documents {
                do {
                    var user = try doc.data(as: FireUserModel.self)
                    user.lastMessageTime = await fetchLastMessageTime(for: user.id)
                    fetchedUsers.append(user)
                } catch {
                    print("Error decoding document \(doc.documentID): \(error)")
                }
            }

            // Sort by lastMessage timestamp
            self.users = sortUsersByLastMessage(fetchedUsers)
            print("Sorted Users array: \(users)")
        } catch {
            print("Error fetching users: \(error.localizedDescription)")
        }
    }

    private func fetchLastMessageTime(for userId: String) async -> Date? {
        do {
            let lastMessageQuery = chatsCollection
                .whereField("userId", isEqualTo: userId)
                .order(by: "timestamp", descending: true)
                .limit(to: 1)

            let lastMessageSnapshot = try await lastMessageQuery.getDocuments()
            if let lastMessageDoc = lastMessageSnapshot.documents.first {
                let lastMessage = try lastMessageDoc.data(as: FireChatModel.self)
                return lastMessage.timestamp
            }
        } catch {
            print("Error fetching last message for user \(userId): \(error)")
        }
        return nil
    }

    private func sortUsersByLastMessage(_ users: [FireUserModel]) -> [FireUserModel] {
        return users.sorted {
            ($0.lastMessageTime ?? .distantPast) > ($1.lastMessageTime ?? .distantPast)
        }
    }

    // MARK: - Profile Image Handling
    func changeProfileImage(userId: String, image: UIImage) async {
        if let imageUrl = await uploadProfileImage(userId: userId, image: image) {
            await updateProfileImage(userId: userId, imageUrl: imageUrl)
        }
    }

    func uploadProfileImage(userId: String, image: UIImage) async -> String? {
        guard let (imageData, fileExtension) = getImageDataAndExtension(image: image) else { return nil }

        let imageRef = storage.child("profile_images/\(userId).\(fileExtension)")

        do {
            let _ = try await imageRef.putDataAsync(imageData)
            let url = try await imageRef.downloadURL()
            return url.absoluteString
        } catch {
            print("Error uploading image: \(error.localizedDescription)")
            return nil
        }
    }

    private func getImageDataAndExtension(image: UIImage) -> (Data, String)? {
        if let pngData = image.pngData() {
            return (pngData, "png")
        } else if let jpegData = image.jpegData(compressionQuality: 0.5) {
            return (jpegData, "jpg")
        }
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
        updateUserField(userId: userId, fieldName: "phone", value: newPhone, completion: completion)
    }

    func updateUserStatus(userId: String, newStatus: String, completion: @escaping (Error?) -> Void) {
        updateUserField(userId: userId, fieldName: "aboutInfo", value: newStatus, completion: completion)
    }

    // MARK: - Helper Methods
    private func updateUserField(userId: String, fieldName: String, value: Any, completion: @escaping (Error?) -> Void) {
        getUserRef(userId: userId).updateData([fieldName: value]) { error in
            completion(error)
        }
    }

    private func updateUserField<T>(userId: String, fieldName: String, value: T) async {
        do {
            try await getUserRef(userId: userId).updateData([fieldName: value])
            print("\(fieldName) updated successfully")
        } catch {
            print("Error updating \(fieldName): \(error.localizedDescription)")
        }
    }

    private func getUserRef(userId: String) -> DocumentReference {
        return usersCollection.document(userId)
    }
}
