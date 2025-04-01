
import SwiftUI
import PhotosUI

struct FireChatListView: View {

    @Environment(FireUserViewModel.self) private var userViewModel : FireUserViewModel
    @Environment(ChatsViewModel.self) var viewModel : ChatsViewModel
    @Environment(AuthViewModel.self) private var authViewModel: AuthViewModel
    @State private var searchText = ""
    @State private var showingSettings = false
    @State var showingContactUsers: Bool = false
    @Binding var selectView: Bool
    @State private var navigationPath = NavigationPath()
    @Binding var currentUser: FireUserModel?
    @Binding var isProfilePicPresented:Bool

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                VStack {
                    scrollViewChatUsers
                        .scrollIndicators(.hidden)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) { whatsAppTitle }
                            ToolbarItemGroup { toolbarButtons }
                        }
                        .navigationDestination(isPresented: $showingSettings, destination: { SettingsView(selectView: $selectView) })
                        .toolbarBackground(.white, for: .navigationBar)
                        .toolbarColorScheme(.light, for: .navigationBar)
                }

                plusButtonToStartANewChat
            }
            .navigationDestination(for: FireUserModel.self) { user in
                FireChatDetailView(user: user, navigationPath: $navigationPath)
            }
            .navigationDestination(isPresented: $showingContactUsers, destination: { FireContactUsersListView(navigationPath: $navigationPath) })
        }
        .onAppear {
            onAppearFunctions()
        }
        .onChange(of: userViewModel.users){
            Task{
                await userViewModel.fetchAllUsersContacts()
                await userViewModel.fetchUsersWithChats( loggedInUserId: authViewModel.currentLoggedInUser?.id ?? "" )
            }
        }
        .onDisappear {
            onDisappearFunctions()
        }
    }

    // MARK: - HELPER FUNCTIONS

    private func onAppearFunctions() {
        Task {
            userViewModel.setupUsersListener()
            await userViewModel.fetchAllUsersContacts()
            await userViewModel.fetchUsersWithChats( loggedInUserId: authViewModel.currentLoggedInUser?.id ?? "" )
        }
    }
    private func onDisappearFunctions() {
        Task{
            await userViewModel.fetchAllUsersContacts()
            await userViewModel.fetchUsersWithChats( loggedInUserId: authViewModel.currentLoggedInUser?.id ?? "" )

        }    }
    // MARK: - COMPONENTS
    private var plusButtonToStartANewChat: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    showingContactUsers = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.customGreen)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }

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
                    ForEach(userViewModel.users) { user in
                        FireChatRow(user: user, currentUser: $currentUser, isProfilePicPresented: $isProfilePicPresented,navigationPath: $navigationPath)
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

//#Preview {
//    @Previewable @State var selectView: Bool = false
//    FireChatListView(selectView: $selectView)
//        .environment(FireUserViewModel())
//        .environment(ChatsViewModel())
//        .environment(AuthViewModel())
//}
