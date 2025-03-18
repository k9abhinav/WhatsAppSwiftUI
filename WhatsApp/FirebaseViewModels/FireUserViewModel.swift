import SwiftUI
import FirebaseFirestore
import FirebaseStorage

@MainActor
@Observable
class FireUserViewModel {
    var users: [FireUserModel] = []
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()

    private var listenerRegistration: ListenerRegistration?

        @MainActor func setupUsersListener() {
            removeListener()

            // Create a new listener
            listenerRegistration = db.collection("users").addSnapshotListener { [weak self] snapshot, error in
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
    /// Fetch all users from Firestore
    @MainActor func fetchUsers() async {
        do {
            let snapshot = try await db.collection("users").getDocuments()
            print("Document count: \(snapshot.documents.count)")

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
            print("Users array: \(users)")
        } catch {
            print("Error fetching users: \(error.localizedDescription)")
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

    func getImageDataAndExtension(image: UIImage) -> (Data, String)? {
        if let pngData = image.pngData() {
            return (pngData, "png")
        } else if let jpegData = image.jpegData(compressionQuality: 0.5) {
            return (jpegData, "jpg")
        }
        return nil
    }

    func updateProfileImage(userId: String, imageUrl: String) async {
        do {
            let data: [String: String] = ["imageUrl": imageUrl] // Typed Dictionary

            try await db.collection("users").document(userId).updateData(data)

            print("Profile image URL updated successfully")
        } catch {
            print("Error updating profile image: \(error.localizedDescription)")
        }
    }

    func changeProfileImage(userId: String, image: UIImage) async {
        if let imageUrl = await uploadProfileImage(userId: userId, image: image) {
            await updateProfileImage(userId: userId, imageUrl: imageUrl)
        }
    }


    func updateUserName(userId: String, newName: String, completion: @escaping (Error?) -> Void) {

        db.collection("users").document(userId).updateData(["name": newName]) { error in
            completion(error)
        }
    }
    func updateUserPhone(userId: String, newPhone: String, completion: @escaping (Error?) -> Void) {
        db.collection("users").document(userId).updateData(["phone": newPhone]) { error in
            completion(error)
        }
    }
    func updateUserStatus(userId: String, newStatus: String, completion: @escaping (Error?) -> Void) {
        db.collection("users").document(userId).updateData(["aboutInfo": newStatus]) { error in
            completion(error)
        }
    }

    
}
