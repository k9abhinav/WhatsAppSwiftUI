
import SwiftUI
import FirebaseFirestore
import FirebaseStorage

@MainActor
@Observable
final class FireUserViewModel {
    // MARK: - Properties
    var users: [FireUserModel] = []
    var allUsers: [FireUserModel] = []
    var triggerProfilePicUpdated = false
    // MARK: - Firebase References
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    private let usersCollection: CollectionReference
    private let chatsCollection: CollectionReference
    private let messagesCollection: CollectionReference
    private var listenerRegistration: ListenerRegistration?

    // MARK: - Init
    init() {
        usersCollection = db.collection("users")
        chatsCollection = db.collection("chats")
        messagesCollection = db.collection("messages")
        print("---   FireUserViewModel initialized ------✅------------------")
    }
    func initializeData(loggedInUserId: String) async {
//        await fetchAllUsersContacts() // Initial cache
        setupUsersListener()
        setupChatsListener(for: loggedInUserId)
    }
    // MARK: - Listeners
    func setupUsersListener() {
        listenerRegistration = usersCollection.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self, let documents = snapshot?.documents, error == nil else {
                print("Error fetching users  -----  ❌ ---------- : \(error?.localizedDescription ?? "Unknown error  -----  ❌ ---------- in setupUsersListener ----")")
                return
            }

            self.allUsers = documents.compactMap {  try? $0.data(as: FireUserModel.self)  }
            let currentUserIds = self.users.map { $0.id }
            self.users = currentUserIds.compactMap { userId in
                self.allUsers.first { $0.id == userId }
            }

            print("Users listener triggered, ------✅-----------  \n allUsers count: \(self.allUsers.count)")

        }
    }
    func setupChatsListener(for loggedInUserId: String) {
        chatsCollection.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self, let documents = snapshot?.documents, error == nil else {
                print("Error fetching chats  -----  ❌ ---------- : \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            var userChatTimestamps: [String: Date] = [:]

            let chatDocuments = documents.compactMap { try? $0.data(as: FireChatModel.self) }

            for chat in chatDocuments where chat.participants.contains(loggedInUserId) {
                if let lastMessageTimestamp = chat.lastSeenTimeStamp {
                    let uniqueParticipants = Set(chat.participants)

                    for participant in uniqueParticipants {
                        let isSelfChat = uniqueParticipants.count == 1 && participant == loggedInUserId
                        let isOtherUser = participant != loggedInUserId

                        if isSelfChat || isOtherUser {
                            userChatTimestamps[participant] = lastMessageTimestamp
                        }
                    }

                } else {
                    print("No lastMessage TimeStamp for CHAT ------❌----------- participants : \(chat.participants)")
                }
            }
            
            let sortedUserIds = userChatTimestamps
                .sorted { $0.value > $1.value }
                .map { $0.key }


            self.users = sortedUserIds.compactMap { userId in
                self.allUsers.first { $0.id == userId }
            }
            print("Chats listener triggered, ------✅----------- \n sorted users count: \(self.users.count)")
        }
    }


    func removeListener() {
        listenerRegistration?.remove()
        print("Users listener removed  --------------❌------------------") // Debug: Listener removed
    }


    // MARK: - User Fetching
    func fetchAllUsersContacts() async {
        do {
            let snapshot = try await usersCollection.getDocuments()
            self.allUsers = snapshot.documents.compactMap { try? $0.data(as: FireUserModel.self) }

            print("Fetched all users, count: \(self.allUsers.count)") // Debug: Fetched all users
        } catch {
            print("Failed to fetch all users  -----  ❌ ---------- : \(error.localizedDescription)") // Debug: Error fetching all users
        }
    }

    func fetchUsersWithChats(loggedInUserId: String) async {
        do {
            let userChatTimestamps = try await fetchUserChatTimestamps(loggedInUserId: loggedInUserId)
            await sortUsersByLastMessage(userChatTimestamps)
        } catch {
            print("Failed to fetch users with chats  -----  ❌ ---------- : \(error.localizedDescription)")
        }
    }

    // 🔹 Fetch chat timestamps for all participants
    private func fetchUserChatTimestamps(loggedInUserId: String) async throws -> [String: Date] {
        let snapshot = try await chatsCollection.getDocuments()
        let chatDocuments = snapshot.documents.compactMap { try? $0.data(as: FireChatModel.self) }

        var userChatTimestamps: [String: Date] = [:]

        for chat in chatDocuments where chat.participants.contains(loggedInUserId) {
            if let lastMessageTimestamp = chat.lastSeenTimeStamp  {
                print("\(lastMessageTimestamp) is there")
                for participant in chat.participants {
                    userChatTimestamps[participant] = lastMessageTimestamp
                }
            } else {
                print("No lastMessage TimeStamp for the CHAT ------❌----------- : \(chat.participants)")
            }
        }

        print("Fetched chat timestamps for ------✅------\(userChatTimestamps.count) users")
        return userChatTimestamps
    }

    // 🔹 Sort users by last message timestamp
    private func sortUsersByLastMessage(_ userChatTimestamps: [String: Date]) async {
        guard !userChatTimestamps.isEmpty else {
            print("No users found with chats ----------------❌---------------")
            print("\n")
            return
        }

        let sortedUserIds = userChatTimestamps
            .sorted { $0.value > $1.value }
            .map { $0.key }

        self.users = sortedUserIds.compactMap { userId in
            allUsers.first { $0.id == userId }
        }
        print("Sorted users with chats, count  ------✅----------- : \(self.users.count)")
    }



    // MARK: - Profile Image Handling
    func changeProfileImage(userId: String, image: UIImage) async -> String? {
        if let imageUrl = await uploadProfileImage(userId: userId, image: image) {
            await updateProfileImage(userId: userId, imageUrl: imageUrl)
            await FireAuthViewModel().loadCurrentUser()
            self.triggerProfilePicUpdated = true
            print("Triggered Profile Pic Updated ----------✅---------")
            return imageUrl
        }
        return nil
    }


    func uploadProfileImage(userId: String, image: UIImage) async -> String? {
        guard let (imageData, fileExtension) = getImageDataAndExtension(image: image) else {
            print("Failed to get image data and extension  -----  ❌ ----------")
            return nil
        }

        let imageRef = storage.child("profile_images/\(userId).\(fileExtension)")

        do {
            let _ = try await imageRef.putDataAsync(imageData)
            let url = try await imageRef.downloadURL()
            print("Image uploaded successfully, URL: ----------✅--------")
            return url.absoluteString
        } catch {
            print("Error uploading image  -----  ❌ ---------- : \(error.localizedDescription)")

            return nil
        }
    }

    private func getImageDataAndExtension(image: UIImage) -> (Data, String)? {
        if let pngData = image.pngData() {
            return (pngData, "png")
        } else if let jpegData = image.jpegData(compressionQuality: 0.5) {
            return (jpegData, "jpg")
        }
        print("Failed to convert image to PNG or JPEG -----  ❌ ----------")

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
                print("Error updating field \(fieldName) ----❌----------  \(error.localizedDescription) ")
            } else {
                print("Field \(fieldName) updated successfully ----------✅-------- \n")
            }
            completion(error)
        }
    }

    private func updateUserField<T>(userId: String, fieldName: String, value: T) async {
        do {
            try await getUserRef(userId: userId).updateData([fieldName: value])
            print("\(fieldName) updated successfully ----------✅--------")
        } catch {
            print("Error updating \(fieldName)  ----❌---------- : \(error.localizedDescription)")
        }
    }

    private func getUserRef(userId: String) -> DocumentReference {
        return usersCollection.document(userId)
    }
}

