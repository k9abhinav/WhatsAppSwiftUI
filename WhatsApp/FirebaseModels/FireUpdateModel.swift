import Foundation

// MARK: - Models
struct FireUpdateModel: Codable, Identifiable, Equatable {
    var id: String
    var userId: String
    var content: String
    var mediaType: MediaType
    var mediaUrl: String?
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

    enum MediaType: String, Codable {
        case text, image, video
    }

    static func == (lhs: FireUpdateModel, rhs: FireUpdateModel) -> Bool {
        return lhs.id == rhs.id
    }
}

