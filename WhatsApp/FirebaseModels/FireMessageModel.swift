import Foundation

struct FireMessageModel: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var chatId: String
    var messageType: MessageType
    var content: String
    var senderUserId: String
    var receiverUserId: String
    var timestamp: Date
    var replyToMessageId: String?
    var isForwarded:Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: FireMessageModel, rhs: FireMessageModel) -> Bool {
        return lhs.id == rhs.id
    }

    enum CodingKeys: String, CodingKey {
        case id,chatId,messageType, content, senderUserId, receiverUserId, timestamp, replyToMessageId,isForwarded
    }
}

enum MessageType: String, Codable {
    case text
    case image
    case video
    case audio
    case location
    case contact
}
