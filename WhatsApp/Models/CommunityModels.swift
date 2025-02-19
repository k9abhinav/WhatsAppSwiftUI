//
//  CommunityModels.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 14/02/25.
//

// CommunityModels.swift
import SwiftUI

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

class CommunitiesViewModel: ObservableObject {
    @Published var communities: [Community] = [
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
}
