import SwiftUI
import PhotosUI
import SwiftData

struct ChatListView: View {

    @Query private var users: [User]
    @Environment(UtilityClass.self) private var utilityVM
    @Environment(\.modelContext) private var modelContext
    @State private var localChatsVM = ChatsViewModel()
    @State private var searchText = ""
    @State private var showingSettings = false
    @Binding var selectView: Bool
    var body: some View {
        NavigationStack {
            VStack {
                scrollViewChatUsers
                    .scrollIndicators(.hidden)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) { whatsAppTitle }
                        ToolbarItemGroup { toolbarButtons }
                    }
                    .navigationDestination(
                        isPresented: $showingSettings,
                        destination: {
                        SettingsView(selectView: $selectView)
                        }
                    )
                    .toolbarBackground(.white, for: .navigationBar)
                    .toolbarColorScheme(.light, for: .navigationBar)
            }
        }
    }

    // MARK: - Computed Properties
    private var filteredUsers: [User] {
        localChatsVM.filteredUsers(users: users, searchText: searchText)
    }

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
            CustomSearchBar(searchText: $searchText,placeholderText: "Ask Meta AI or Search")
                .cornerRadius(20)
                .padding(.horizontal, 8)
                .padding(.top, 12)
                .padding(.bottom,5)
            horizontalChatCategories
            renderUserChats
        }
    }

    private var renderUserChats: some View {
        LazyVStack(spacing: 17) {
            if filteredUsers.isEmpty && !searchText.isEmpty {
                Text("No matches found")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(filteredUsers) { user in
                    ChatRow(user: user,localChatsVM: localChatsVM)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 50)
    }

    private var horizontalChatCategories: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(utilityVM.chatCategories, id: \.self) { category in
                    Text(category)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.customGreen)
                        )
                        .fixedSize()
                }
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: 50)
    }
}


#Preview {

}
