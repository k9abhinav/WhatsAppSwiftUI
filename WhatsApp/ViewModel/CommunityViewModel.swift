//
//  CommunityViewModel.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 27/02/25.
//
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
}
