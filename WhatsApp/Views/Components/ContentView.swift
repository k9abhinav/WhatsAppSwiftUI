import SwiftUI

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
    }
}
