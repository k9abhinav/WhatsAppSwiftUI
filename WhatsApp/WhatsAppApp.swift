
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
    @State private var contactsManager = ContactsManager()
    @State private var settingsViewModel = SettingsViewModel()
    let container: ModelContainer

    init() {
        do {
            // Create a ModelConfiguration
            let schema = Schema([ChatMessage.self,Status.self])
            container = try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(contactsManager)
                .environment(settingsViewModel)
                .modelContainer(container)
        }
    }
}
