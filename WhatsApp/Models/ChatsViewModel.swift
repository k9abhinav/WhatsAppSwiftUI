//
//  ChatsViewModel.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 13/02/25.
//

// ChatViewModel.swift
import Foundation

class ChatsViewModel: ObservableObject {
    @Published var chats: [Chat] = [
        Chat(name: "Abhinava", lastMessage: "Hello", isRead: true, timestamp: Date(), profileImage: "person.crop.circle"),
        Chat(name: "John", lastMessage: "How are you?", isRead: false, timestamp: Date().addingTimeInterval(-3600), profileImage: "person.crop.circle"),
//        Chat(name: "Sarah", lastMessage: "See you tomorrow!", isRead: true, timestamp: Date().addingTimeInterval(-7200), profileImage: "person.crop.circle"),
//        Chat(name: "Diana", lastMessage: "See you in sometime!", isRead: true, timestamp: Date().addingTimeInterval(-7200), profileImage: "person.crop.circle"),
        Chat(name: "RAHUL", lastMessage: "See you later!", isRead: true, timestamp: Date().addingTimeInterval(-7200), profileImage: "person.crop.circle"),
        Chat(name: "Smith", lastMessage: "Bye!", isRead: true, timestamp: Date().addingTimeInterval(-7200), profileImage: "person.crop.circle"),
        Chat(name: "Travis", lastMessage: "Ok!", isRead: true, timestamp: Date().addingTimeInterval(-7200), profileImage: "person.crop.circle"),
        Chat(name: "Pavitra", lastMessage: "Lets see tomorrow!", isRead: true, timestamp: Date().addingTimeInterval(-7200), profileImage: "person.crop.circle"),
        Chat(name: "Shetty", lastMessage: "See you!", isRead: true, timestamp: Date().addingTimeInterval(-7200), profileImage: "person.crop.circle"),
        Chat(name: "Laksh", lastMessage: "See you tomorrow!", isRead: true, timestamp: Date().addingTimeInterval(-7200), profileImage: "person.crop.circle"),
        // Add more dummy data as needed
    ]
}
