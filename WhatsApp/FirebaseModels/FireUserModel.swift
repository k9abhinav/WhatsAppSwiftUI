import Foundation

struct FireUserModel: Identifiable, Codable {
    var id: String
    var phone: String
    var name: String
    var imageUrl: String?
    var aboutInfo: String?
    var email: String?
    var typeOfAuth: AuthType?
    var lastMessageTime: Date?
    var onlineStatus: Bool?

    enum CodingKeys: String, CodingKey {
        case id, phone, name, imageUrl, aboutInfo, email, typeOfAuth, lastMessageTime, onlineStatus
    }
}
