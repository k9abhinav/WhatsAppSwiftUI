import SwiftUI
import SwiftData

struct ProfileDetailsView: View {
//    let user: User
    let user: FireUserModel
    @Environment(\.dismiss) private var dismiss
    @Environment(FireChatViewModel.self) private var chatViewModel: FireChatViewModel
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var profileImageIsActive: Bool = false
    // Sample data for media counts
    @State private var mediaCount: Int = 48
    @State private var linksCount: Int = 12
    @State private var docsCount: Int = 7

    // Search results
    @State private var searchResults: [Chat] = []

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if isSearching { searchBar }
                ScrollView {
                    VStack(spacing: 0) {
                        profileHeader
                        if !isSearching {
                            mediaLinksDocsSection
                                .padding(.top, 8)
                        }
                        if isSearching { searchResultsSection }
                        else {
                            mutesAndEncryptionSection
                            blockAndReportSection
                        }
                    }
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isSearching {
                        Button(action: { isSearching = false }) {
                            Image(systemName: "arrow.backward")
                        }
                    } else {
                        Button(action: { dismiss() }) {
                            Image(systemName: "arrow.backward")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isSearching {
                        EmptyView()
                    } else {
                        HStack {
                            Button(action: { isSearching = true }) {
                                Image(systemName: "magnifyingglass")
                            }
                            
                            Menu {
                                Button("Share contact", action: {})
                                Button("Edit contact", action: {})
                                Button("View in address book", action: {})
                                Button("Clear chat", action: {})
                            } label: {
                                Image(systemName: "ellipsis")
                            }
                        }
                    }
                }
            }
            .toolbarBackground(.white, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)

            if profileImageIsActive {
                        ProfilePicOverlay(user: user) {
                            withAnimation { profileImageIsActive = false }
                        }
                    }
        }
    }

    // MARK: - Components
    private var searchBar: some View {
        CustomSearchBar(searchText: $searchText, placeholderText: "Search chats...")
            .cornerRadius(20)
            .padding(5)
            .onChange(of: searchText) { _, newValue in
                withAnimation(.smooth) {
                performSearch(query: newValue)
            }
        }
    }
    private var profileHeader: some View {
        VStack(spacing: 16) {
            profileImage
                .frame(width: 80, height: 80)
                .padding(.top, 16)
                .onTapGesture {
                    profileImageIsActive.toggle()
                }
            Text(user.name)
                .font(.title2)
                .fontWeight(.bold)

            Text("Online")
                .font(.footnote)
                .foregroundColor(.gray)

            HStack(spacing: 30) {
                actionButton(iconName: "message.fill", title: "Message")
                actionButton(iconName: "phone.fill", title: "Audio")
                actionButton(iconName: "video.fill", title: "Video")
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }

    private var mediaLinksDocsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Media, Links, and Docs")

            NavigationLink(destination: Text("Media Gallery")) {
                mediaRow(title: "Media", count: mediaCount, iconName: "photo.on.rectangle")
            }

            Divider().padding(.leading, 16)

            NavigationLink(destination: Text("Links")) {
                mediaRow(title: "Links", count: linksCount, iconName: "link")
            }

            Divider().padding(.leading, 16)

            NavigationLink(destination: Text("Documents")) {
                mediaRow(title: "Documents", count: docsCount, iconName: "doc.text")
            }
        }
        .background(Color(.systemBackground))
    }

    private var mutesAndEncryptionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Chat Settings")

            HStack {
                Image(systemName: "bell.slash.fill")
                    .foregroundColor(.gray)
                    .frame(width: 24)
                Text("Mute notifications")
                Spacer()
                Text("Off")
                    .foregroundColor(.gray)
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.footnote)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().padding(.leading, 16)

            HStack {
                Image(systemName: "music.note")
                    .foregroundColor(.gray)
                    .frame(width: 24)
                Text("Custom tone")
                Spacer()
                Text("Default")
                    .foregroundColor(.gray)
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.footnote)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().padding(.leading, 16)

            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Encryption")
                    Text("Messages are end-to-end encrypted")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .padding(.top, 16)
    }

    private var blockAndReportSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Privacy")

            Button(action: {}) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.gray)
                        .frame(width: 24)
                    Text("Block \(user.name)")
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            Divider().padding(.leading, 16)

            Button(action: {}) {
                HStack {
                    Image(systemName: "hand.thumbsdown.fill")
                        .foregroundColor(.gray)
                        .frame(width: 24)
                    Text("Report \(user.name)")
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(Color(.systemBackground))
        .padding(.top, 16)
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if searchResults.isEmpty && !searchText.isEmpty {
                Text("No messages found")
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if !searchResults.isEmpty {
                ForEach(searchResults, id: \.id) { message in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatMessageDate(message.timestamp))
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text(message.content)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    Divider().padding(.leading, 16)
                }
            } else {
                Text("Start typing to search messages")
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Helper Views

    private var profileImage: some View {
            Group {
                if let imageUrlString = user.imageUrl, let imageUrl = URL(string: imageUrlString) {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .empty:
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        case .failure:
                            ProgressView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .foregroundColor(.gray)
                }
            }
        }


    private func actionButton(iconName: String, title: String) -> some View {
        VStack {
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(.customGreen)
                .frame(width: 40, height: 40)
                .background(Color.green.opacity(0.1))
                .clipShape(Circle())

            Text(title)
                .font(.caption)
                .foregroundColor(.customGreen)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.footnote)
            .foregroundColor(.gray)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGroupedBackground))
    }

    private func mediaRow(title: String, count: Int, iconName: String) -> some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.gray)
                .frame(width: 24)

            Text(title)

            Spacer()

            Text("\(count)")
                .foregroundColor(.gray)

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.footnote)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Helper Functions

    private func performSearch(query: String) {
        if query.isEmpty {
            searchResults = []
            return
        }

        // Filter messages based on search query
        // This is a placeholder - you'll need to implement the actual search logic
        // based on your data model
//        searchResults = chatViewModel.messages.first?.content filter { message in
//            message.content.lowercased().contains(query.lowercased())
//        }
    }

    private func formatMessageDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
//    Group {
//        // Create a sample user for preview
//        let user = User( id: "" , phone:"",name: "John Doe", lastSeen: Date() , password: "", chats: [Chat(id: UUID(), content: "",isFromCurrentUser: false)])
//        ProfileDetailsView(user: user)
//    }
}
