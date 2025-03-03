
import SwiftUI

struct ContentView: View {

    @State private var isShowingSplash = true

    var body: some View {

        if isShowingSplash {  SplashScreen(splashViewActive: $isShowingSplash)  }
        else { MainTabView() }
        
    }
}
