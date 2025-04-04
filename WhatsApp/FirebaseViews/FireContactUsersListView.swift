import SwiftUI

struct FireContactUsersListView: View {
  
    @Environment(FireUserViewModel.self) private var userViewModel: FireUserViewModel
    @Environment(FireAuthViewModel.self) private var authViewModel: FireAuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @Binding var navigationPath: NavigationPath
    var body: some View {
        VStack {
            if isLoading { ProgressView() }
            else {
                List { createChatsSection ; allContactUsersSection }
                    .listStyle(.plain)
                    .listRowSeparator(.hidden)
            }
        }
        .onAppear {
            onAppearFunctions()
        }
        .navigationBarBackButtonHidden()
        .toolbar{
            ToolbarItemGroup(placement: .topBarLeading) {
                backButton ; navBarContent
            }
        }
    }

    //    ------------------------------------- MARK : COMPONENTS ----------------------------------------------------
    private var navBarContent: some View {
        VStack(alignment: .leading){
            Text("Select contact")
                .font(.headline)
            Text("\(userViewModel.allUsers.count) contacts")
                .font(.caption)
        }.foregroundStyle(.secondary).padding(.leading, 10)
    }
    private var backButton: some View {
        Button(action: { dismiss() })
        {  Image(systemName: "arrow.backward").tint(.secondary) }
    }
    private var allContactUsersSection: some View {
        Section(header:
                    Text("Contacts on WhatsApp")
            .font(.headline)
            .padding(.leading, 10)
            .padding(.bottom, 10)
        ) {
            ForEach(userViewModel.allUsers) { user in
                FireContactUsersRow(user: user,navigationPath: $navigationPath)
            }
        }
    }
    private var createChatsSection: some View {
        Section {
            NewChatCreateRows(imageSysName: "person.2.badge.plus.fill", text: "New Group")
            NewChatCreateRows(imageSysName: "person.fill.badge.plus", text: "New Contact")
            NewChatCreateRows(imageSysName: "person.3.fill", text: "New Community")
            NewChatCreateRows(imageSysName: "bubbles.and.sparkles.fill", text: "Chat with AI's")
        }
    }
    private func onAppearFunctions() {
        Task {
            await userViewModel.fetchAllUsersContacts()
            isLoading = false
        }
    }
}


