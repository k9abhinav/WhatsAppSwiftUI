
import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth

@main
struct WhatsAppApp: App {
    @State private var contactsManager : ContactsManager
    @Environment(\.modelContext) private var modelContext: ModelContext
    let container: ModelContainer

    init() {
        FirebaseApp.configure()

        if let firebaseApp = FirebaseApp.app() { print("Firebase configured successfully: \(firebaseApp)") }
        else {  print("Firebase configuration failed!") }

        do {
            let schema = Schema([User.self,Chat.self])
            container = try ModelContainer(for: schema)
            print("SwiftData container initialized successfully")
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
        let modelContext = container.mainContext
        contactsManager = ContactsManager(modelContext: modelContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(contactsManager)
                .modelContainer(container)
        }
    }
}
