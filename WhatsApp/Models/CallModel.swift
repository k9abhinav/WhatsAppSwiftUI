//
//  CallModels.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 14/02/25.
//

// CallModels.swift
import SwiftUI

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

@Observable class CallsViewModel {
     var calls: [Call] = [
        Call(
            contactName: "John Doe",
            profileImage: "person.circle.fill",
            callType: .audio,
            callDirection: .incoming,
            timestamp: Date().addingTimeInterval(-3600),
            missedCall: false,
            callCount: 1
        ),
        Call(
            contactName: "Jane Smith",
            profileImage: "person.circle.fill",
            callType: .video,
            callDirection: .outgoing,
            timestamp: Date().addingTimeInterval(-7200),
            missedCall: false,
            callCount: 2
        ),
        Call(
            contactName: "Alice Johnson",
            profileImage: "person.circle.fill",
            callType: .audio,
            callDirection: .incoming,
            timestamp: Date().addingTimeInterval(-10800),
            missedCall: true,
            callCount: 1
        )
    ]
}
