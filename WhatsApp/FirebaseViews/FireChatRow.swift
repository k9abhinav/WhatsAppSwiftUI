
import SwiftUI
import PhotosUI

struct FireChatRow: View {
    let user: FireUserModel
    @Binding var currentUser: FireUserModel?
    @Binding var isProfilePicPresented:Bool
    @State private var lastMessage: FireChatModel?
    @Environment(FireChatViewModel.self) private var chatViewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var profileImageURLString: String? = ""
    var body: some View {
        NavigationLink( destination: FireChatDetailView(user:user) )
        {
            HStack {
                Button(
                    action: {
                        currentUser = user
                        isProfilePicPresented.toggle()
                    },
                    label: { userProfilePictureView }
                ).buttonStyle(PlainButtonStyle())
                userProfileNameandContent
                Spacer()
                userLastSeenTime
            }
            .padding(.vertical,5)
            //            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .onAppear {
            Task {
                chatViewModel.listenAndFetchLastChat(currentUserId: authViewModel.currentLoggedInUser?.id ?? "" , otherUserId: user.id ) { latestMessage in
                    if let message = latestMessage {
                        lastMessage = message
                    }
                }
                profileImageURLString = user.imageUrl
            }
        }
        .onChange(of: chatViewModel.chatMessages.count){
            Task{
                chatViewModel.listenAndFetchLastChat(currentUserId: authViewModel.currentLoggedInUser?.id ?? "" , otherUserId: user.id ) { latestMessage in
                    if let message = latestMessage {
                        lastMessage = message
                    }
                }
            }
        }
    }
    // MARK: SUB-COMPONENTS -----
    private var userLastSeenTime: some View {
        VStack {
            let date: Date = user.lastMessageTime ??  .now
            Text(timeString(from: date))
                .font(.caption)
                .fontWeight(.light)
                .foregroundStyle(.gray.opacity(0.8))
        }
    }
    private var userProfileNameandContent: some View {
        VStack(alignment: .leading,spacing: 6) {
            HStack {
                Text(user.name)
                    .font(.headline)
                if user.id == authViewModel.currentLoggedInUser?.id {
                    Text("(You)")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            }

            HStack(spacing:12 ){
                Image("doubleCheck")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 5, height: 5)
                    .scaleEffect(3.5)

                Text(lastMessage?.content ?? "No Message")
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.gray)
            }
            .padding(.leading,5)
        }
    }
    private var userProfilePictureView: some View {
        AsyncImage(url: URL(string: user.imageUrl ?? "")) { phase in
            switch phase {
            case .empty:
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)

            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            case .failure:
                ProgressView() // Show loading indicator
            @unknown default:
                EmptyView()
            }
        }
    }
    // MARK: HELPER FUNCTIONS -------------------------------
    private func timeString(from date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
            return formatter.string(from: date)  // Example: "2:30 PM"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)  // Example: "Mar 4, 2025"
        }
    }


}

#Preview {
    FireChatRow(user: FireUserModel(id: "123", phone: "", name: "Test User", imageUrl: nil),
                currentUser: .constant(nil),
                isProfilePicPresented: .constant(false))
    .environment(FireChatViewModel())
    .environment(AuthViewModel())
}
