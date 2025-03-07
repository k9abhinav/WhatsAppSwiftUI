

import SwiftUI
import SwiftData
import FirebaseAuth
struct ContentView: View {
    @State private var splashViewActive = true
    @State private var isUserLoggedIn: Bool = Auth.auth().currentUser != nil
    @State private var authListenerHandle: AuthStateDidChangeListenerHandle?
    var body: some View {
        Group {
            if splashViewActive {
                SplashScreen(splashViewActive: $splashViewActive)
            } else  {
                if isUserLoggedIn { MainTabView() }
                else {  SignUpView() }
            }
        }
        .animation(.easeOut(duration: 0.3), value: splashViewActive)
        .onAppear {
            authListenerHandle = Auth.auth().addStateDidChangeListener { _, user in
                isUserLoggedIn = (user != nil)
            }
        }
        .onDisappear {
            if let handle = authListenerHandle {
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }
}









//        .onAppear { contactsManager.requestAccess() }

//    @Environment(ContactsManager.self) private var contactsManager : ContactsManager
//    @Environment(\.modelContext) var modelContext: ModelContext
//    init(modelContext: ModelContext) {
//        _contactsManager = Environment(wrappedValue: ContactsManager(modelContext: modelContext))
//       }
//    ------------- For ContactsManager to load users as Contacts if not available ---------------------------------


//func clearUserDefaults() {
//    let defaults = UserDefaults.standard
//    for key in defaults.dictionaryRepresentation().keys {
//        defaults.removeObject(forKey: key)
//    }
//    defaults.synchronize()
//}
//clearUserDefaults()
