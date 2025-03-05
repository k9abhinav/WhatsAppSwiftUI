import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var splashViewActive = true
    var body: some View {
        Group {
            if splashViewActive {
                SplashScreen(splashViewActive: $splashViewActive)
            } else {
                MainTabView()
            }
        }
        .animation(.easeOut(duration: 0.3), value: splashViewActive)
//        .onAppear { contactsManager.requestAccess() }
    }
}






//    @Environment(ContactsManager.self) private var contactsManager : ContactsManager
//    @Environment(\.modelContext) var modelContext: ModelContext
//    init(modelContext: ModelContext) {
//        _contactsManager = Environment(wrappedValue: ContactsManager(modelContext: modelContext))
//       }
//    ------------- For ContactsManager to load users as Contacts if not available ---------------------------------
