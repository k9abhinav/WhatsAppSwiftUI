
import SwiftUI
import FirebaseFirestore

@Observable
class UpdateViewModel {
    var updates: [FireUpdateModel] = []
    private let db = Firestore.firestore()

    /// Fetch updates and delete expired ones
    func fetchUpdates(for userId: String) async {
        let now = Date()
        let updatesRef = db.collection("updates").whereField("userId", isEqualTo: userId)

        do {
            let snapshot = try await updatesRef.getDocuments()
            var validUpdates: [FireUpdateModel] = []
            for document in snapshot.documents {
                let update = try document.data(as: FireUpdateModel.self)
                if update.expiresAt < now {
                    try await db.collection("updates").document(update.id).delete()
                } else {
                    validUpdates.append(update)
                }
            }
            self.updates = validUpdates.sorted { $0.createdAt > $1.createdAt }
        } catch {
            print("❌ Error fetching updates: \(error.localizedDescription)")
        }
    }

    /// Add a new update (status)
    func addUpdate(for userId: String, content: String, imageUrl: String?) async {
        let now = Date()
        let newUpdate = FireUpdateModel(
            id: UUID().uuidString,
            userId: userId,
            content: content,
            imageUrl: imageUrl,
            createdAt: now,
            expiresAt: Calendar.current.date(byAdding: .hour, value: 24, to: now)!
        )

        do {
            try db.collection("updates").document(newUpdate.id).setData(from: newUpdate)
        } catch {
            print("❌ Error adding update: \(error.localizedDescription)")
        }
    }

    /// Delete a specific update manually
    func deleteUpdate(for updateId: String) async {
        do {
            try await db.collection("updates").document(updateId).delete()
        } catch {
            print("❌ Error deleting update: \(error.localizedDescription)")
        }
    }
}
