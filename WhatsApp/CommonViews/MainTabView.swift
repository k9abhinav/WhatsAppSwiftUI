
import SwiftUI

struct MainTabView: View {

    @State private var selectedTab = 0
    @State var selectView: Bool = true
    @State var currentUser: FireUserModel?
    @State var currentMessage: FireMessageModel?
    @State var isProfilePicPresented = false
    @State var chatImageDetailView : Bool = false
    @Environment(FireAuthViewModel.self) private var authViewModel
    var body: some View {

        ZStack {
            TabView(selection: $selectedTab) {
                if selectView {
                    FireChatListView(selectView: $selectView, currentUser: $currentUser, isProfilePicPresented: $isProfilePicPresented, chatImageDetailView: $chatImageDetailView, currentMessage: $currentMessage )
                        .tabItem {
                            Label("Chats", systemImage: "ellipsis.message.fill")
                        }
                        .tag(0)
                        .badge(1)
                    FireUpdatesView(userId: authViewModel.currentLoggedInUser?.id ?? "")
                        .tabItem {
                            Label("Updates", systemImage: "timer.circle")
                        }
                        .tag(1)
                } else {
                    ChatListView(selectView: $selectView)
                        .tabItem {
                            Label("Chats", systemImage: "ellipsis.message.fill")
                        }
                        .tag(0)
                        .badge(1)
                    UpdatesView()
                        .tabItem {
                            Label("Updates", systemImage: "timer.circle")
                        }
                        .tag(1)
                }


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
//            .tint(Color(#colorLiteral(red: 0.2178634405, green: 0.582372725, blue: 0.9793615937, alpha: 1)))
            .tint(.primary)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(.white, for: .tabBar)
            profilePicOverlayZStack
            chatImageOverlayZStack
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
    private var  chatImageOverlayZStack : some View {
        Group{
            if chatImageDetailView {
                ChatImageOverlay(message: currentMessage){
                    withAnimation { chatImageDetailView = false }
                }
            }
        }
    }
}
#Preview {

}
