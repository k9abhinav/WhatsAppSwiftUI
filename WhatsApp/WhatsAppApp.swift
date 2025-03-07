
//  WhatsAppApp.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 13/02/25.
//
import SwiftUI
import SwiftData
import FirebaseCore
@main
struct WhatsAppApp: App {
    @State private var authViewModel : AuthViewModel
    @State private var callsViewModel = CallsViewModel()
    @State private var communityViewModel = CommunityViewModel()
    @State private var chatsViewModel = ChatsViewModel()
    //    @State private var contactsManager = ContactsManager()
    let container: ModelContainer

    init() {
        FirebaseApp.configure()
        do {
            let schema = Schema([User.self,Chat.self])
            container = try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
        authViewModel = AuthViewModel()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
//                .environment(contactsManager)
                .environment(authViewModel)
                .environment(chatsViewModel)
                .environment(callsViewModel)
                .environment(communityViewModel)
                .modelContainer(container)
        }
    }
}

