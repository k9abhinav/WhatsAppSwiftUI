//
//  UserModel.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 27/02/25.
//
import Foundation
import SwiftData

@Model
class User {
    var id : String = UUID().uuidString
    @Attribute(.unique) var phone: String
    var name: String
    var imageData: Data?
    var lastSeen: Date?
    var password: String?
    @Relationship(deleteRule: .cascade) var chats: [Chat] = []

   init(id: String, phone: String, name: String, imageData: Data? = nil, lastSeen: Date? = nil, password: String? = nil, chats: [Chat]) {
        self.id = id
        self.phone = phone
        self.name = name
        self.imageData = imageData
        self.lastSeen = lastSeen
        self.password = password
        self.chats = chats
    }
    var lastChatMessage: Chat? {
            return chats.last
        }   
}

