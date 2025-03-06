import SwiftUI
import PhotosUI
import SwiftData

struct ChatListView: View {

    @Environment(ChatsViewModel.self) var viewModel : ChatsViewModel
    @Query private var users: [User]
    @State private var searchText = ""
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            VStack {
                scrollViewChatUsers
                    .scrollIndicators(.hidden)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) { whatsAppTitle }
                        ToolbarItemGroup { toolbarButtons }
                    }
                    .sheet(isPresented: $showingSettings) {
                        SettingsView()
                    }
                    .toolbarBackground(.white, for: .navigationBar)
                    .toolbarColorScheme(.light, for: .navigationBar)
            }
        }
    }


    // MARK: - Computed Properties
    private var filteredUsers: [User] {
        viewModel.filteredUsers(users: users, searchText: searchText)
    }

    // MARK: - Components
    private var whatsAppTitle: some View {
        Text("WhatsApp")
            .font(.title)
            .fontWeight(.semibold)
            .foregroundColor(.green)
    }

    private var toolbarButtons: some View {
        HStack {
            PhotosPicker(selection: .constant(nil), matching: .images, photoLibrary: .shared()) {
                Image(systemName: "qrcode.viewfinder")
            }
            PhotosPicker(selection: .constant(nil), matching: .images, photoLibrary: .shared()) {
                Image(systemName: "camera")
            }
            Button(action: {    showingSettings.toggle()  }) {
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .fontWeight(.semibold)
            }
        }
    }

    private var scrollViewChatUsers: some View {
        ScrollView {
            VStack {
                CustomSearchBar(searchText: $searchText,placeholderText: "Ask Meta AI or Search")
            }
            .cornerRadius(20)
            .padding(.horizontal, 8)
            .padding(.top, 12)

            VStack(spacing: 17) {
                if filteredUsers.isEmpty && !searchText.isEmpty {
                    Text("No matches found")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(filteredUsers) { user in
                        ChatRow(user: user)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
        }
    }
}


