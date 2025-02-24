
    //  WhatsAppApp.swift
    //  WhatsApp
    //
    //  Created by Abhinava Krishna on 13/02/25.
    //

    // WhatsAppApp.swift
    import SwiftUI
import SwiftData
    @main
    struct WhatsAppApp: App {
        @StateObject private var contactsManager = ContactsManager()
        let container: ModelContainer

            init() {
                do {
                    // Create a ModelConfiguration
                    container = try ModelContainer(for: ChatMessage.self)
                } catch {
                    fatalError("Failed to initialize SwiftData container: \(error)")
                }
            }

        var body: some Scene {
            WindowGroup {
                ContentView()
                    .environmentObject(contactsManager)
                    .modelContainer(container)
            }
        }
    }
