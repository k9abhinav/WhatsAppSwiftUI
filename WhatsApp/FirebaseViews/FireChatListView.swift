

import SwiftUI
import PhotosUI

struct FireChatListView: View {
    @Environment(FireUserViewModel.self) private var userViewModel : FireUserViewModel
    @Environment(ChatsViewModel.self) var viewModel : ChatsViewModel
    @Environment(AuthViewModel.self) private var authViewModel: AuthViewModel
    @State  var currentUser: FireUserModel!
    @State private var searchText = ""
    @State private var showingSettings = false
    @State  var isProfilePicPresented = false
    var body: some View {

            NavigationStack {
                ZStack {
                    VStack {
                        scrollViewChatUsers
                            .scrollIndicators(.hidden)
                            .toolbar {
                                ToolbarItem(placement: .topBarLeading) { whatsAppTitle }
                                ToolbarItemGroup { toolbarButtons }
                            }
                            .navigationDestination(isPresented: $showingSettings, destination: { SettingsView() })
                            .toolbarBackground(.white, for: .navigationBar)
                            .toolbarColorScheme(.light, for: .navigationBar)
                    }
                    if isProfilePicPresented {
                        ProfilePicOverlay(user: currentUser) {
                                    withAnimation { isProfilePicPresented = false }
                                }
                            }
                }
            }
            .onAppear {
                Task {
                    await userViewModel.fetchUsers()  
                    userViewModel.setupUsersListener()
                }
            }
        }



    // MARK: - Computed Properties

    // MARK: - Components
    private var whatsAppTitle: some View {
        Text("WhatsApp")
            .font(.title)
            .fontWeight(.semibold)
            .foregroundColor(Color.customGreen)
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
            .padding(.bottom,5)

            horizontalChatCategories

            VStack(spacing: 17) {
                if userViewModel.users.isEmpty && !searchText.isEmpty {
                    Text("No matches found")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(userViewModel.users.filter { $0.id != authViewModel.currentLoggedInUser?.id }) { user in
                        FireChatRow(user: user, currentUser: $currentUser, isProfilePicPresented: $isProfilePicPresented)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
        }
    }
    private var horizontalChatCategories: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.chatCategories, id: \.self) { category in
                    Text(category)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16) // Padding for dynamic width
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.customGreen)
                        )
                        .fixedSize() // Ensures the capsule only takes as much space as needed
                }
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: 50)
    }
}

#Preview {
    FireChatListView()
        .environment(FireUserViewModel())
        .environment(ChatsViewModel())
        .environment(AuthViewModel())
}
