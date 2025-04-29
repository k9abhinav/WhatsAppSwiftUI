
import SwiftUI
import PhotosUI

struct FireChatListView: View {

    @Environment(FireUserViewModel.self) private var userViewModel : FireUserViewModel
    @Environment(FireChatViewModel.self) private var chatViewModel: FireChatViewModel
    @Environment(UtilityClass.self) private var utilityVM: UtilityClass
    @Environment(FireAuthViewModel.self) private var authViewModel: FireAuthViewModel
    @FocusState private var isSearchFocused: Bool
    @State private var searchText = ""
    @State private var showingSettings = false
    @State var showingContactUsers: Bool = false
    @Binding var selectView: Bool
    @State var navigationPath: NavigationPath = NavigationPath()
    @Binding var currentUser: FireUserModel?
    @Binding var isProfilePicPresented:Bool
    @Binding var chatImageDetailView : Bool
    @Binding var currentChatImageData: Data?
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
                            destination: {
                                FireSettingsView (
                                    selectView: $selectView,
                                    navigationPath: $navigationPath
                                )
                            }
                        )
                        .navigationDestination(for: UserNavigationData.self) { navData in
                            FireChatDetailView(
                                userId: navData.user.id,
                                imageURLData: navData.imageData,
                                navigationPath: $navigationPath,
                                chatImageDetailView: $chatImageDetailView,
                                currentChatImageData: $currentChatImageData
                            )
                        }
                        .navigationDestination(
                            isPresented: $showingContactUsers,
                            destination: { FireContactUsersListView( navigationPath: $navigationPath) })
                        .searchable(text: $searchText, placement: .automatic, prompt: "Ask Meta AI or Search")
                        .searchFocused($isSearchFocused)
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
    private var filteredUsers: [FireUserModel]  {
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
    private func loadImage(for urlString: String?) async -> Data? {
        guard let url = URL(string: urlString ?? "") else {
            print("No URL provided for image")
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data // No need for DispatchQueue.main, as we're returning data
        } catch {
            print("Failed to load image data: \(error.localizedDescription)")
            return nil
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
        Menu {
            optionButton(title: "Select chats", icon: "checkmark.circle")
            optionButton(title: "Read all", icon: "checkmark.bubble")
        } label: {
            Image(systemName: "ellipsis")
                .fontWeight(.semibold)
        }
        .buttonStyle(.plain)
    }

    // Extracted View: Menu Option Buttons
    private func optionButton(title: String, icon: String) -> some View {
        Button(action: {}) {
            HStack {
                Text(title)
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .padding(.leading, 5)
            }
        }
    }

    private var encryptionNotice: some View {
        HStack {
            Image(systemName: "lock.fill")
                .resizable()
                .frame(width: 10, height: 10)
            Text("Your personal messages are")
            Text("end-to-end encrypted")
                .foregroundColor(.green)
        }
        .font(.caption)
    }

    private var scrollViewChatUsers: some View {
        ScrollView {
            VStack(spacing: 17) {
                if !isSearchFocused { horizontalChatCategories }
                contentView
                encryptionNotice
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if filteredUsers.isEmpty {
            emptyStateView
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
    private var emptyStateView: some View {
        VStack {
            Image("startChat")
                .resizable()
                .frame(width: 250, height: 250)
                .scaledToFit()
            Text(isSearchFocused ? "No such results" : "Start a chat... Tap (+) icon")
                .font(.caption)
                .foregroundColor(.gray)
                .padding()
        }
    }
    private var horizontalChatCategories: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(utilityVM.chatCategories, id: \.self) { category in
                    categoryChip(for: category)
                }
                addCategoryButton
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: 50)
    }

    // Extracted View: Category Chip
    private func categoryChip(for category: String) -> some View {
        Text(category)
            .font(.caption)
            .foregroundColor(.gray)
            .padding(.horizontal, 16)
            .fontWeight(.semibold)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(category == "All" ? Color.customGreen.opacity(0.5) : Color.gray.opacity(0.2))
            )
            .fixedSize()
    }

    // Extracted View: Add Category Button
    private var addCategoryButton: some View {
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
                utilityVM.chatCategories.append(" New Category ")
            }
    }

}






#Preview {
    //    @Previewable @State var selectView: Bool = false
    //    @Previewable @State var currentUser: FireUserModel? = nil
    //    @Previewable @State var isProfilePicPresented: Bool = false
    //
    //    FireChatListView(selectView: $selectView, currentUser: $currentUser, isProfilePicPresented: $isProfilePicPresented)
    //        .environment(FireUserViewModel())
    //        .environment(ChatsViewModel())
    //        .environment(FireChatViewModel())
    //        .environment(FireAuthViewModel())
}

