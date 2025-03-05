
//  WhatsAppApp.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 13/02/25.
//
import SwiftUI
import SwiftData

@main
struct WhatsAppApp: App {
//    @State private var contactsManager = ContactsManager()
    @State private var callsViewModel = CallsViewModel()
    @State private var communityViewModel = CommunityViewModel()
    @State private var chatsViewModel = ChatsViewModel()
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([User.self,Chat.self])
            container = try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
//                .environment(contactsManager)
                .environment(chatsViewModel)
                .environment(callsViewModel)
                .environment(communityViewModel)
                .modelContainer(container)
        }
    }
}
