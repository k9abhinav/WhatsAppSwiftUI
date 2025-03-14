
import SwiftUI

struct MainTabView: View {

    @State private var selectedTab = 0

    var body: some View {

        TabView(selection: $selectedTab) {
//            ChatListView()
            FireStoreListView()
                .tabItem {
                    Label("Chats", systemImage: "ellipsis.message.fill")
                }
                .tag(0)

            UpdatesView()
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
                .badge(5)
        }

        .tint(.customGreen)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.white, for: .tabBar)
    }
}
