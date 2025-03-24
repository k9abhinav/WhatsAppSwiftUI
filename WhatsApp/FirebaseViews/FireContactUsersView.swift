
import SwiftUI

struct FireContactUsersView: View {
    @Environment(FireUserViewModel.self) private var userViewModel: FireUserViewModel
    @Environment(AuthViewModel.self) private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    
    var body: some View {
        VStack {
            // User list
            List {
                Section{
                    NewRows(imageSysName: "person.2.badge.plus.fill", text: "New Group")
                    NewRows(imageSysName: "person.fill.badge.plus", text: "New Contact")
                    NewRows(imageSysName: "person.3.fill", text: "New Community")
                    NewRows(imageSysName: "bubbles.and.sparkles.fill", text: "Chat with AI's")
                }
                Section( header:
                            Text("Contacts on WhatsApp")
                                .font(.headline)
                                .padding(.leading, 10)
                                .padding(.vertical, 10)
                ){
                    ForEach(userViewModel.allUsers) { user in
                        FireNewChatRow(user:user)
                    }
                }
            }
            .listStyle(.plain).listRowSeparator(.hidden)
        }
        .onAppear{
            Task{
                await userViewModel.fetchUsers()
            }
        }
        .navigationTitle("New Chat")
        .navigationBarTitleDisplayMode(.automatic)
    }

}

struct NewRows: View {
    let imageSysName: String
    let text: String
    var body: some View {
        HStack {
            Image(systemName: imageSysName)
            Text(text)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
        }
        .padding(.vertical,10)
        .padding(.horizontal,10)
    }
}
