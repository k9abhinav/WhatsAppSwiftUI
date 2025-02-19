import SwiftUI

// MainTabView.swift
struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var contactsManager: ContactsManager

    var body: some View {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    ChatRowView()
                }
                .tabItem {
                    Label("Chats", systemImage: "ellipsis.message.fill")
                }
                .tag(0)

                NavigationStack {
                    StatusView()
                }
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
    }
}
#Preview {
    MainTabView()
}
