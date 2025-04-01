import Foundation

struct FireUserModel: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var phoneNumber: String?
    var name: String
    var imageUrl: String?
    var aboutInfo: String?
    var createdDate: Date?
    var email: String?
    var password: String?
    var typeOfAuth: AuthType?
    var lastSeenTime: Date?
    var onlineStatus: Bool?
    var currentSessionId: String?

    enum CodingKeys: String, CodingKey {
        case id, phoneNumber, name, imageUrl, aboutInfo,createdDate, email,password, typeOfAuth, lastSeenTime, onlineStatus,currentSessionId
    }
}

enum AuthType: String ,Codable {
    case email
    case google
    case phone
    case linkedWithGoogle
    case unknown
}
