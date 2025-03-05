
import Foundation

struct Community: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let groups: [CommunityGroup]
    let memberCount: Int
    let announcements: [Announcement]
}

struct CommunityGroup: Identifiable {
    let id = UUID()
    let name: String
    let memberCount: Int
    let lastMessage: String
    let timestamp: Date
}

struct Announcement: Identifiable {
    let id = UUID()
    let content: String
    let sender: String
    let timestamp: Date
}

