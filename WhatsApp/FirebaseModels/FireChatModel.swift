
import Foundation
import FirebaseCore

struct FireChatModel : Identifiable, Codable {
    var id: String = UUID().uuidString
    var chatType: ChatType
    var participants: [String]
    var creationDate: Date
    var groupName: String?
    var groupPictureStringURL: String?
    var groupAdminId: String?
    var groupDescription: String?
    var lastMessageId: String?

    func toDictionary() -> [String: Any] {
            return [
                "id": id,
                "chatType": chatType.rawValue,
                "participants": participants,
                "creationDate": Timestamp(date: creationDate),
                "lastMessageId": lastMessageId ?? NSNull()
            ]
        }

    enum CodingKeys: String, CodingKey {
        case id, chatType, participants, creationDate, groupName, groupPictureStringURL, groupAdminId, groupDescription, lastMessageId
    }
}

enum ChatType: String, Codable {
    case group
    case single
}
