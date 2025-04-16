
import Foundation

struct Call: Identifiable {
    let id = UUID()
    let contactName: String
    let profileImage: String
    let callType: CallType
    let callDirection: CallDirection
    let timestamp: Date
    let missedCall: Bool
    let callCount: Int
}

enum CallType {
    case audio
    case video
}

enum CallDirection {
    case incoming
    case outgoing
}
