
import SwiftUI
import PhotosUI

struct FireChatRow: View {
    let user: FireUserModel
    @Binding var currentUser: FireUserModel?
    @Binding var isProfilePicPresented:Bool
    @State private var lastMessage: FireChatModel?
    @Environment(FireChatViewModel.self) private var chatViewModel
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
        .onAppear{
            Task{
                lastMessage = await chatViewModel.fetchLastChat(for: user.id)
                profileImageURLString = user.imageUrl
            }
            }
    }
    // MARK: SUB-COMPONENTS -----
    private var userLastSeenTime: some View {
        VStack {
            let date: Date = user.lastSeen ??  .now
            Text(timeString(from: date))
                .font(.caption)
                .fontWeight(.light)
                .foregroundStyle(.gray.opacity(0.8))
        }
    }
    private var userProfileNameandContent: some View {
        VStack(alignment: .leading,spacing: 6) {
            Text(user.name)
                .font(.headline)

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
            Group {
                if let imageUrlString = profileImageURLString , let imageUrl = URL(string: imageUrlString) {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .empty:
                            ProgressView() // Show a loading indicator
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        case .failure:
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.gray)
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
    
}
