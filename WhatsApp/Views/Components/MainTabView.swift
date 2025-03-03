
import SwiftUI

struct MainTabView: View {

    @Environment(CommunityViewModel.self) var communityViewModel
    @Environment(CallsViewModel.self) var callsViewModel
    @Environment(ChatsViewModel.self) var chatsViewModel
    @State private var selectedTab = 0

    var body: some View {

            TabView(selection: $selectedTab) {
                ChatRowView(viewModel: chatsViewModel)

                    .tabItem {
                        Label("Chats", systemImage: "ellipsis.message.fill")
                    }
                    .tag(0)

                UpdatesView()
                    .tabItem {
                        Label("Updates", systemImage: "timer.circle")
                    }
                    .tag(1)

                CommunitiesView(viewModel: communityViewModel)
                    .tabItem {
                        Label("Communities", systemImage: "person.3.fill")
                    }
                    .tag(2)

                CallsView(viewModel: callsViewModel)
                    .tabItem {
                        Label("Calls", systemImage: "phone.fill")
                    }
                    .tag(3)
                    .badge(5)
            }
     
        .tint(.green)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.white, for: .tabBar)
    }
}
