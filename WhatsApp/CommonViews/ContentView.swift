import SwiftUI
import SwiftData
import FirebaseAuth

struct ContentView: View {
    @State private var splashViewActive = true
    @State private var isUserLoggedIn = Auth.auth().currentUser != nil
    @State private var authListenerHandle: AuthStateDidChangeListenerHandle?
    @State private var isLoading = true
    @State private var userViewModel = FireUserViewModel()
    @State private var updateViewModel = FireUpdateViewModel()
    @State private var messageViewModel = FireMessageViewModel()
    @State private var chatViewModel = FireChatViewModel()
    @State private var utilityViewModel = UtilityClass()
    @State private var authViewModel = FireAuthViewModel()
    var body: some View {
        Group {
            if splashViewActive {
                SplashView(splashViewActive: $splashViewActive)
            } else {
                contentView
                    .environment(userViewModel)
                    .environment(messageViewModel)
                    .environment(chatViewModel)
                    .environment(updateViewModel)
                    .environment(utilityViewModel)
                    .environment(authViewModel)
            }
        }
        .animation(.easeOut(duration: 0.3), value: splashViewActive)
        .onAppear(perform: setupAuthListener)
        .onDisappear(perform: removeAuthListener)
    }

    private var contentView: some View {
        Group {
            if isUserLoggedIn {
                if isLoading {
                    LoadingView()
                } else {
                    MainTabView()
                }
            } else {
                WelcomeView()
            }
        }
        .animation(.smooth(duration: 0.75), value: isUserLoggedIn)
    }

    private func setupAuthListener() {
        authListenerHandle = Auth.auth().addStateDidChangeListener { _, user in
            isUserLoggedIn = (user != nil)
        }

        let isFirstInstall = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")

        if isFirstInstall {
            do {
                try Auth.auth().signOut()
            }catch {
                print("\(error.localizedDescription)")
            }
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }

        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation { isLoading = false }
        }
    }


    private func removeAuthListener() {
        authListenerHandle.map { Auth.auth().removeStateDidChangeListener($0) }
    }

}
