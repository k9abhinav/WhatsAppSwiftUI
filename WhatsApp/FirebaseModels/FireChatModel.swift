import Foundation
import FirebaseCore
import FirebaseFirestore // Required for Timestamp

struct FireChatModel: Identifiable, Codable {
    var id: String = UUID().uuidString
    var chatType: ChatType
    var participants: [String]
    var creationDate: Date
    var groupName: String?
    var groupPictureStringURL: String?
    var groupAdminId: String?
    var groupDescription: String?
    var lastMessageId: String?
    var lastMessageContent: String?
    var lastSeenTimeStamp: Date?
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "chatType": chatType.rawValue,
            "participants": participants,
            "creationDate": Timestamp(date: creationDate),
            "groupName": groupName ?? NSNull(),
            "groupPictureStringURL": groupPictureStringURL ?? NSNull(),
            "groupAdminId": groupAdminId ?? NSNull(),
            "groupDescription": groupDescription ?? NSNull(),
            "lastMessageId": lastMessageId ?? NSNull(),
            "lastMessageContent": lastMessageContent ?? NSNull() 
        ]
    }

    enum CodingKeys: String, CodingKey {
        case id, chatType, participants, creationDate, groupName, groupPictureStringURL, groupAdminId, groupDescription, lastMessageId, lastMessageContent
    }
}


enum ChatType: String, Codable {
    case group
    case single
}
