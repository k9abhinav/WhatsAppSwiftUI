

import SwiftUI


// ContentView.swift
struct ContentView: View {
    @State private var isShowingSplash = true
    @EnvironmentObject var contacrsManager: ContactsManager

    var body: some View {
        Group {
            if isShowingSplash {
                SplashScreen(isActive: $isShowingSplash)
            } else {
                MainTabView()
            }
        }
    }
}
