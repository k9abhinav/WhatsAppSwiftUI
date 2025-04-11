
import SwiftUI
import PhotosUI

struct FireChatListView: View {

    @Environment(FireUserViewModel.self) private var userViewModel : FireUserViewModel
    @Environment(ChatsViewModel.self) private var viewModel : ChatsViewModel
    @Environment(FireChatViewModel.self) private var chatViewModel: FireChatViewModel
    @Environment(FireAuthViewModel.self) private var authViewModel: FireAuthViewModel
    @State private var searchText = ""
    @State private var showingSettings = false
    @State var showingContactUsers: Bool = false
    @Binding var selectView: Bool
    @State var navigationPath: NavigationPath = NavigationPath()
    @Binding var currentUser: FireUserModel?
    @Binding var isProfilePicPresented:Bool

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                VStack {
                    scrollViewChatUsers
                        .scrollIndicators(.hidden)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) { chatOptionsButton }
                            ToolbarItemGroup { toolbarButtons }
                        }
                        .toolbarBackground(.white, for: .navigationBar)
                        .toolbarColorScheme(.light, for: .navigationBar)
                        .navigationTitle("Chats")
                        .navigationDestination(
                            isPresented: $showingSettings,
                            destination: { FireSettingsView(selectView: $selectView, navigationPath: $navigationPath) }
                        )
                        .navigationDestination(for: FireUserModel.self) { user in
                            FireChatDetailView(userId: user.id, navigationPath: $navigationPath)
                        }
                        .navigationDestination(
                            isPresented: $showingContactUsers,
                            destination: { FireContactUsersListView(navigationPath: $navigationPath) })
                        .searchable(text: $searchText, placement: .automatic, prompt: "Ask Meta AI or Search")
                }
                // ZStack Overlay
                plusButtonToStartANewChat
            }
            .onAppear {
                Task {
                    await userViewModel.initializeData(loggedInUserId: authViewModel.currentLoggedInUser?.id ?? "")
                }
            }
            .onDisappear { userViewModel.removeListener() }
        }


    }

    // MARK: - HELPER FUNCTIONS
    private var filteredUsers: [FireUserModel] {
        if searchText.isEmpty {
            return userViewModel.users
        } else {
            return userViewModel.users.filter { user in
                let matchesName = user.name.localizedCaseInsensitiveContains(searchText)
                let matchesPhone = user.phoneNumber?.localizedCaseInsensitiveContains(searchText) ?? false
                return matchesName || matchesPhone
            }
        }
    }

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
                Image(systemName: "camera.fill")
            }
            Button(action: {    showingSettings.toggle()  } ) {
                Image(systemName: "gear")
                    .rotationEffect(.degrees(90))
                    .fontWeight(.semibold)
            }
        }
    }
    private var chatOptionsButton: some View {
        Menu{
            Button(action: {},label: {
                HStack(){
                    Text("Select chats")
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.gray)
                        .padding(.leading, 5)
                }

            }
            )
            Button(action: {},label: {
                HStack(){
                    Text("Read all")
                    Image(systemName: "checkmark.bubble")
                        .foregroundColor(.gray)
                        .padding(.leading, 5)
                }
            }
            )
        } label: {
            Image(systemName: "ellipsis")
                .fontWeight(.semibold)
        }
        .buttonStyle(.plain)

    }
    private var scrollViewChatUsers: some View {
        ScrollView {
            //            VStack {
            //                CustomSearchBar(searchText: $searchText,placeholderText: "Ask Meta AI or Search")
            //            }
            //            .cornerRadius(20)
            //            .padding(.horizontal, 10)
            //            .padding(.top, 12)
            //            .padding(.bottom,10)

            horizontalChatCategories

            LazyVStack(spacing: 17)  {
                if filteredUsers.isEmpty {
                    VStack{
                        Text("No matches found")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding()

                    }
                } else {
                    ForEach(filteredUsers) { user in
                        FireChatRow(
                            userId: user.id,
                            currentUser: $currentUser,
                            isProfilePicPresented: $isProfilePicPresented,
                            navigationPath: $navigationPath
                        )
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
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .fontWeight(.semibold)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.2))
                        )
                        .fixedSize()
                }
                Text(" + ")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                    .fontWeight(.semibold)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                    )
                    .fixedSize()
                    .onTapGesture {
                        viewModel.chatCategories.append(" New Category ")
                    }

            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: 50)
    }
}

#Preview {
    @Previewable @State var selectView: Bool = false
    @Previewable @State var currentUser: FireUserModel? = nil
    @Previewable @State var isProfilePicPresented: Bool = false

    FireChatListView(selectView: $selectView, currentUser: $currentUser, isProfilePicPresented: $isProfilePicPresented)
        .environment(FireUserViewModel())
        .environment(ChatsViewModel())
        .environment(FireChatViewModel())
        .environment(FireAuthViewModel())
}

