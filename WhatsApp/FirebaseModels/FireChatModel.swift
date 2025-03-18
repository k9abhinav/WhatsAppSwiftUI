import Foundation

struct FireChatModel: Codable, Identifiable {
    var id: String
    var content: String
    var isFromCurrentUser: Bool
    var timestamp: Date
    var userId: String 

    enum CodingKeys: String, CodingKey {
        case id, content, isFromCurrentUser, timestamp, userId
    }
}
