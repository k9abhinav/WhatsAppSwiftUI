//
//  Chat.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 13/02/25.
//
import Foundation
import SwiftData

@Model
class Chat {
    var id: UUID
    var content: String
    var isFromCurrentUser: Bool
    var timestamp: Date
    @Relationship(inverse: \User.chats) var user: User?

    init(id: UUID = UUID(), content: String, isFromCurrentUser: Bool, user: User? = nil) {
         self.id = UUID()
         self.content = content
         self.isFromCurrentUser = isFromCurrentUser
         self.timestamp = Date()

         self.user = user
     }
}
