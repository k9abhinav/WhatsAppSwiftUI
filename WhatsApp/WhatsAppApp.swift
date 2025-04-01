
import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth

@main
struct WhatsAppApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var authViewModel : AuthViewModel
    @State private var callsViewModel = CallsViewModel()
    @State private var communityViewModel = CommunityViewModel()
    @State private var chatsViewModel = ChatsViewModel()
    @State private var chatViewModel :FireChatViewModel
    @State private var userViewModel  :FireUserViewModel
    @State private var messageViewModel : FireMessageViewModel
    @State private var contactsManager : ContactsManager
    @Environment(\.modelContext) private var modelContext: ModelContext
    let container: ModelContainer

    init() {
        FirebaseApp.configure()

        if let firebaseApp = FirebaseApp.app() { print("Firebase configured successfully: \(firebaseApp)") }
        else {  print("Firebase configuration failed!") }
//        Auth.auth().settings?.isAppVerificationDisabledForTesting = false
//        print("Firebase Auth settings updated (Testing mode enabled)")
        do {
            let schema = Schema([User.self,Chat.self])
            container = try ModelContainer(for: schema)
            print("SwiftData container initialized successfully")
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
        let modelContext = container.mainContext
        authViewModel = AuthViewModel()
        chatViewModel = FireChatViewModel()
        userViewModel = FireUserViewModel()
        messageViewModel = FireMessageViewModel()
        contactsManager = ContactsManager(modelContext: modelContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authViewModel)
                .environment(messageViewModel)
                .environment(chatsViewModel)
                .environment(callsViewModel)
                .environment(communityViewModel)
                .environment(chatViewModel)
                .environment(userViewModel)
                .modelContainer(container)
                .environment(contactsManager)
            //            PhoneAuthTestView()
            //                .onOpenURL { url in
            //                          print("Received URL: \(url)")
            //                          Auth.auth().canHandle(url) // <- just for information purposes
            //                        }
        }
    }
}





//class AppDelegate: NSObject, UIApplicationDelegate {
//  func application(_ application: UIApplication,
//                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//    FirebaseApp.configure()
//
//    return true
//  }
//}
