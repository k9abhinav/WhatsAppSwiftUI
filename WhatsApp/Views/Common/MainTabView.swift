
import SwiftUI

struct MainTabView: View {

    @State private var selectedTab = 0
    @State var selectView: Bool = true
    @State var currentUser: FireUserModel?
    @State var isProfilePicPresented = false
    var body: some View {

        ZStack {
            TabView(selection: $selectedTab) {
                if selectView {
                    FireChatListView(selectView: $selectView, currentUser: $currentUser, isProfilePicPresented: $isProfilePicPresented)
                        .tabItem {
                            Label("Chats", systemImage: "ellipsis.message.fill")
                        }
                        .tag(0)
                        .badge(1)
                } else {
                    ChatListView(selectView: $selectView)
                        .tabItem {
                            Label("Chats", systemImage: "ellipsis.message.fill")
                        }
                        .tag(0)
                        .badge(1)
                }
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
            }
            .tint(.customGreen)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(.white, for: .tabBar)
            profilePicOverlayZStack
        }
    }
    private var profilePicOverlayZStack: some View {
        Group{
            if isProfilePicPresented {
                ProfilePicOverlay(user: currentUser) {
                    withAnimation { isProfilePicPresented = false }
                }
            }
        }
    }
}
#Preview {

}
