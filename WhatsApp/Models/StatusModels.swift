//
//  StatusModels.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 14/02/25.
//

// StatusModels.swift
import SwiftUI

struct Status: Identifiable {
    let id = UUID()
    let user: String
    let profileImage: String
    let timePosted: Date
    let caption: String
    var isViewed: Bool
    var updates: [StatusUpdate]
}

struct StatusUpdate: Identifiable {
    let id = UUID()
    let content: String
    let timestamp: Date
    var isViewed: Bool
}
// @Observale
class StatusViewModel: ObservableObject {
    @Published var statuses: [Status] = [
        Status(
            user: "My Status",
            profileImage: "person.circle.fill",
            timePosted: Date(),
            caption: "Tap to add status update",
            isViewed: false,
            updates: []
        ),
        Status(
            user: "John Doe",
            profileImage: "person.circle.fill",
            timePosted: Date().addingTimeInterval(-3600),
            caption: "At the beach! 🏖️",
            isViewed: false,
            updates: [
                StatusUpdate(content: "At the beach!", timestamp: Date().addingTimeInterval(-3600), isViewed: false)
            ]
        ),
        Status(
            user: "Jane Smith",
            profileImage: "person.circle.fill",
            timePosted: Date().addingTimeInterval(-7200),
            caption: "Working from home today",
            isViewed: true,
            updates: [
                StatusUpdate(content: "Working from home", timestamp: Date().addingTimeInterval(-7200), isViewed: true)
            ]
        ), Status(
            user: "Dane Henry",
            profileImage: "person.circle.fill",
            timePosted: Date().addingTimeInterval(-3800),
            caption: "At Home! 🏖️",
            isViewed: false,
            updates: [
                StatusUpdate(content: "At the beach!", timestamp: Date().addingTimeInterval(-3600), isViewed: false)
            ]
        )
    ]
}
