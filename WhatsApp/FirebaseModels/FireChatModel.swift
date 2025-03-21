import Foundation

struct FireChatModel: Codable, Identifiable, Hashable {
    var id: String
    var content: String
    var senderUserId: String
    var receiverUserId: String
    var timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id, content, senderUserId, receiverUserId, timestamp
    }
}
