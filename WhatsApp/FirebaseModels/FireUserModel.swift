import Foundation

struct FireUserModel: Identifiable, Codable {
    var id: String 
    var phone: String
    var name: String
    var imageUrl: String?
    var lastSeen: Date?
    var password: String?
    var aboutInfo: String?
    var email: String?
    var authType: AuthType?

    enum CodingKeys: String, CodingKey {
        case id, phone, name, imageUrl, lastSeen, password, aboutInfo, email, authType
    }
}

enum AuthType: String ,Codable {
    case email
    case google
    case phone
    case unknown
}
