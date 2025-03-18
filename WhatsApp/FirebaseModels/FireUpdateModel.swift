import Foundation

struct FireUpdateModel: Codable, Identifiable {
    var id: String
    var userId: String 
    var content: String
    var imageUrl: String?
    var createdAt: Date
    var expiresAt: Date

    var isExpired: Bool {
        return Date() > expiresAt
    }

    var timeRemaining: String {
        let remaining = expiresAt.timeIntervalSince(Date())
        if remaining <= 0 { return "Expired" }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        return hours > 0 ? "\(hours)h \(minutes)m remaining" : "\(minutes)m remaining"
    }
}

