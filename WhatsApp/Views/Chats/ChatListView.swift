import SwiftUI
import PhotosUI
import SwiftData

struct ChatListView: View {

    @Environment(ChatsViewModel.self) var viewModel : ChatsViewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
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
                    .navigationDestination(isPresented: $showingSettings, destination: { SettingsView(selectView: $selectView) })
                    .toolbarBackground(.white, for: .navigationBar)
                    .toolbarColorScheme(.light, for: .navigationBar)
            }
        }
        .onAppear {
//            createSampleUsersAndInsert()
        }
    }

//    func createSampleUsersAndInsert() {
//        let chat1 = Chat(content: "Hello!", isFromCurrentUser: true, user: nil)
//        let user1 = User(id: UUID().uuidString, phone: "123-456-7890", name: "Alice Smith", password: "password123", chats: [chat1])
//
//        // Insert into context
//        modelContext.insert(user1)
//        do {
//            try modelContext.save()
//            print("User inserted successfully")
//        } catch {
//            print("Error inserting user: \(error)")
//        }
//    }
    // MARK: - Computed Properties
    private var filteredUsers: [User] {
        viewModel.filteredUsers(users: users, searchText: searchText)
    }

    // MARK: - Components
    private var whatsAppTitle: some View {
        Text("WhatsApp")
            .font(.title)
            .fontWeight(.semibold)
//            .foregroundStyle(Color.rainbow)
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

}
