import Foundation

struct FireUserModel: Identifiable, Codable, Hashable,Equatable {
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
    var isTyping: Bool?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FireUserModel, rhs: FireUserModel) -> Bool {
        return lhs.id == rhs.id
    }

    enum CodingKeys: String, CodingKey {
        case id, phoneNumber, name, imageUrl, aboutInfo,createdDate, email,password, typeOfAuth, lastSeenTime, onlineStatus,currentSessionId,isTyping
    }

}

enum AuthType: String ,Codable {
    case email
    case google
    case phone
    case linkedWithGoogle
    case unknown
}
