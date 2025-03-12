import SwiftUI
import Firebase

struct FireStoreListView: View {
    @Environment(AuthViewModel.self) private var viewModel : AuthViewModel
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack {
                searchBar

                List(filteredUsers) { user in
                    FireChatRow(user: user)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Chats")
            .onAppear {
                Task {
                    await viewModel.fetchAllUsers()
                }
            }
        }
    }

    private var filteredUsers: [FireUserModel] {
        if searchText.isEmpty {
            return viewModel.allUsers
        } else {
            return viewModel.allUsers.filter {
                $0.fullName.lowercased().contains(searchText.lowercased()) ||
                ($0.email?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
    }

    private var searchBar: some View {
        TextField("Search users...", text: $searchText)
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
    }
}

struct FireChatRow: View {
    let user: FireUserModel

    var body: some View {
        HStack {
            if let imageURL = user.profileImageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
            }

            VStack(alignment: .leading) {
                Text(user.fullName)
                    .font(.headline)
                if let email = user.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            Spacer()
        }
        .padding(.vertical, 5)
    }
}
