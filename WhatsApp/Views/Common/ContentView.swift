

import SwiftUI
import SwiftData
import FirebaseAuth
struct ContentView: View {
    @State private var splashViewActive = true
    @State private var isUserLoggedIn: Bool = Auth.auth().currentUser != nil
    @State private var authListenerHandle: AuthStateDidChangeListenerHandle?
    @State private var isLoading = true
    //    @Environment(ContactsManager.self) var contactsManager:ContactsManager
    var body: some View {
        Group {
            if splashViewActive {
                SplashView(splashViewActive: $splashViewActive)
            } else  {
                if isUserLoggedIn {
                    withAnimation(.easeIn(duration: 0.3)) {
                        ZStack {
                            if isLoading { LoadingView() }
                            else { MainTabView()  }
                        }
                    }
                }
                else {  withAnimation(.easeIn(duration: 0.3)) { WelcomeView() }
                }
            }
        }
        .animation(.easeOut(duration: 0.3), value: splashViewActive)
        .onAppear {
            authListenerHandle = Auth.auth().addStateDidChangeListener { _, user in
                isUserLoggedIn = (user != nil)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    isLoading = false
                }
            }
            //            contactsManager.requestAccess()
        }
        .onDisappear {
            if let handle = authListenerHandle {
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }

    }
}
extension Color {
    static let customGreen = Color(UIColor(red: 0.22, green: 0.67, blue: 0.49, alpha: 1.0))
}
import SwiftUI

extension Color {
    static var rainbow: some ShapeStyle {
        LinearGradient(
            stops: [
                .init(color: Color(red: 122/255, green: 229/255, blue: 83/255), location: 0.0),
                .init(color: Color(red: 179/255, green: 203/255, blue: 54/255), location: 0.143),
                .init(color: Color(red: 216/255, green: 78/255, blue: 87/255), location: 0.286),
                .init(color: Color(red: 242/255, green: 191/255, blue: 28/255), location: 0.429),
                .init(color: Color(red: 42/255, green: 161/255, blue: 208/255), location: 0.572),
                .init(color: Color(red: 94/255, green: 196/255, blue: 138/255), location: 0.714),
                .init(color: Color(red: 97/255, green: 124/255, blue: 184/255), location: 0.857),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
extension LinearGradient {
    static let rainbow = LinearGradient(
        stops: [
            .init(color: Color(red: 122/255, green: 229/255, blue: 83/255), location: 0.0),
            .init(color: Color(red: 179/255, green: 203/255, blue: 54/255), location: 0.143),
            .init(color: Color(red: 216/255, green: 78/255, blue: 87/255), location: 0.286),
            .init(color: Color(red: 242/255, green: 191/255, blue: 28/255), location: 0.429),
            .init(color: Color(red: 42/255, green: 161/255, blue: 208/255), location: 0.572),
            .init(color: Color(red: 94/255, green: 196/255, blue: 138/255), location: 0.714),
            .init(color: Color(red: 97/255, green: 124/255, blue: 184/255), location: 0.857),
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
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
