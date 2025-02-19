//
//  Chat.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 13/02/25.
//

import Foundation

struct Chat: Identifiable {
    let id = UUID()
    let name: String
    let lastMessage: String
    let isRead: Bool
    let timestamp: Date
    let profileImage: String // For system image name
}
