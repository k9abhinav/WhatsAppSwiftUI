
import Foundation

@Observable class CommunityViewModel {
     var communities: [Community] = [
        Community(
            name: "Local Neighborhood",
            description: "Community for our neighborhood residents",
            icon: "building.2.fill",
            groups: [
                CommunityGroup(
                    name: "General Announcements",
                    memberCount: 150,
                    lastMessage: "Next community meeting on Friday",
                    timestamp: Date()
                ),
                CommunityGroup(
                    name: "Events Planning",
                    memberCount: 45,
                    lastMessage: "Summer festival preparations",
                    timestamp: Date().addingTimeInterval(-3600)
                )
            ],
            memberCount: 200,
            announcements: [
                Announcement(
                    content: "Welcome to our community! Please read the guidelines.",
                    sender: "Admin",
                    timestamp: Date().addingTimeInterval(-86400)
                )
            ]
        )
    ]

    func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)

        if let day = components.day, day > 0 {
            return day == 1 ? "Yesterday" : "\(day)d ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute {
            return "\(minute)m ago"
        } else {
            return "Just now"
        }
    }

}
