
import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth

@main
struct WhatsAppApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var authViewModel : AuthViewModel
    @State private var callsViewModel = CallsViewModel()
    @State private var communityViewModel = CommunityViewModel()
    @State private var chatsViewModel = ChatsViewModel()
    @State private var chatViewModel :FireChatViewModel
    @State private var userViewModel  :FireUserViewModel
    //    @State private var contactsManager = ContactsManager()
    let container: ModelContainer

    init() {
        FirebaseApp.configure()

        if let firebaseApp = FirebaseApp.app() { print("Firebase configured successfully: \(firebaseApp)") }
        else {  print("Firebase configuration failed!") }
        Auth.auth().settings?.isAppVerificationDisabledForTesting = false
        print("Firebase Auth settings updated (Testing mode enabled)")
        do {
            let schema = Schema([User.self,Chat.self])
            container = try ModelContainer(for: schema)
            print("SwiftData container initialized successfully")
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
        authViewModel = AuthViewModel()
        chatViewModel = FireChatViewModel()
        userViewModel = FireUserViewModel()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authViewModel)
                .environment(chatsViewModel)
                .environment(callsViewModel)
                .environment(communityViewModel)
                .environment(chatViewModel)
                .environment(userViewModel)
                .modelContainer(container)
            //                .environment(contactsManager)
            //            PhoneAuthTestView()
            //                .onOpenURL { url in
            //                          print("Received URL: \(url)")
            //                          Auth.auth().canHandle(url) // <- just for information purposes
            //                        }
        }
    }
}

