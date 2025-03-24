
import Foundation

struct FireChatModel : Identifiable, Codable {
    var id: String = UUID().uuidString
    var chatType: ChatType
    var partcipants: [FireUserModel]
    var creationDate: Date
    var groupName: String?
    var groupPictureStringURL: String?
    var groupAdminId: String?
    var groupDescription: String?
    var lastMessageId: String?

    enum CodingKeys: String, CodingKey {
        case id, chatType, partcipants, creationDate, groupName, groupPictureStringURL, groupAdminId, groupDescription, lastMessageId
    }
}

enum ChatType: String, Codable {
    case group
    case single
}
