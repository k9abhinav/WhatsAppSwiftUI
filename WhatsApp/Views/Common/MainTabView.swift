import SwiftUI

// MainTabView.swift

struct MainTabView: View {
    @State private var selectedTab = 0
    @Environment(ContactsManager.self) var contactsManager
    @Environment(SettingsViewModel.self) var settingsViewModel


    var body: some View {
        TabView(selection: $selectedTab) {

            NavigationStack {
                ChatRowView(contactsManager: contactsManager)
            }
            .tabItem {
                Label("Chats", systemImage: "ellipsis.message.fill")
            }
//            .symbolEffect(.disappear)
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
                .badge(5)
                .tag(3)

        }
        .tint(.green)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.white, for: .tabBar)
    }
}




#Preview {
//    MainTabView()
//        .environment(ContactsManager())
}
