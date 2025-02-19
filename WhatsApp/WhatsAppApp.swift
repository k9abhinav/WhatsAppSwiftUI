
    //  WhatsAppApp.swift
    //  WhatsApp
    //
    //  Created by Abhinava Krishna on 13/02/25.
    //

    // WhatsAppApp.swift
    import SwiftUI

    @main
    struct WhatsAppApp: App {
        @StateObject private var contactsManager = ContactsManager()

        var body: some Scene {
            WindowGroup {
                ContentView()
                    .environmentObject(contactsManager)
            }
        }
    }
