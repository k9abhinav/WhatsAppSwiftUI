import Foundation

struct FireUserModel: Identifiable, Codable {
    var id: String // Firebase document ID
    var phone: String
    var name: String
    var imageUrl: String? // URL to Firebase Storage
    var lastSeen: Date?
    var password: String?
    var aboutInfo: String?
    var email: String?
    var authType: AuthType?

    enum CodingKeys: String, CodingKey {
        case id, phone, name, imageUrl, lastSeen, password, aboutInfo, email, authType
    }
}

enum AuthType: Codable {
    case email
    case google
    case phone
    case unknown
}
