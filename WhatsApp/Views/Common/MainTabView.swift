import SwiftUI

// MainTabView.swift

class NavigationState: ObservableObject {
    @Published var isChatDetailActive = false
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var contactsManager: ContactsManager
    @StateObject private var navigationState = NavigationState()

    var body: some View {
        TabView(selection: $selectedTab) {

            NavigationStack {
                ChatRowView()
                    .environmentObject(navigationState)
            }
            .tabItem {
                Label("Chats", systemImage: "ellipsis.message.fill")
            }
            .tag(0)
        

            StatusView()
                .tabItem {
                    Label("Updates", systemImage: "timer.circle")
                }
                .tag(1)

            CommunitiesView()
                .tabItem {
                    Label("Communities", systemImage: "person.3.fill")
                }
                .tag(2)

            CallsView()
                .tabItem {
                    Label("Calls", systemImage: "phone.fill")
                }
                .tag(3)

        }
        .tint(.green)  // This replaces .accentColor which is deprecated
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.white, for: .tabBar)
        .toolbar(navigationState.isChatDetailActive ? .hidden : .visible, for: .tabBar)
    }
}
#Preview {
    MainTabView()
}
