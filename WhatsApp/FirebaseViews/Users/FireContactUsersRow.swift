
import SwiftUI

struct FireContactUsersRow: View {
//    let user: FireUserModel
    let userId:String
    var user: FireUserModel {
        userViewModel.allUsers.first { $0.id == userId } ?? FireUserModel(name: "Unknown")
    }
    @State private var lastMessage: FireMessageModel?
    @Environment(FireChatViewModel.self) private var chatViewModel
    @Environment(FireUserViewModel.self) private var userViewModel
    @Environment(FireAuthViewModel.self) private var authViewModel
    @Binding var navigationPath: NavigationPath

    var body: some View {
        Button {
                   navigationPath.append(user)
               } label:
        {
            HStack {
                userProfilePictureView
                userProfileNameandContent
                Spacer()
            }
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
        .onAppear {
            userViewModel.setupUsersListener()
        }
        .onDisappear {
            userViewModel.removeListener()
        }
    }

    // MARK: SUB-COMPONENTS -----------
    private var userLastSeenTime: some View {
        VStack {
            let date: Date = user.lastSeenTime ??  .now
            Text(timeString(from: date))
                .font(.caption)
                .fontWeight(.light)
                .foregroundStyle(.gray.opacity(0.8))
        }
    }
    private var userProfileNameandContent: some View {
        VStack(alignment: .leading,spacing: 6) {
            HStack {
                Text(user.name )
                    .font(.headline)
                if user.id == authViewModel.currentLoggedInUser?.id {
                    Text("(You)")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            }
            Text(user.aboutInfo ?? "Error in loading about")
                .font(.subheadline)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(.gray)

                .padding(.leading,5)
        }
    }
    private var userProfilePictureView: some View {
        Group {
            if let imageUrlString = user.imageUrl, let imageUrl = URL(string: imageUrlString) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 50,height: 50)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50,height: 50)
                            .clipShape(Circle())

                    case .failure:
                        defaultProfileImage
                    @unknown default:
                        EmptyView()
                            .frame(width: 50,height: 50)
                    }
                }

            }
            else{
                defaultProfileImage
            }
        }
    }
    private var defaultProfileImage: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFill()
            .frame(width: 50, height: 50)
            .foregroundColor(.gray)
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

//#Preview {
//    @Previewable @State var navigationPath: NavigationPath = NavigationPath()
//    FireContactUsersRow(user: FireUserModel(id: "123", phoneNumber: "99", name: "Test User", imageUrl: nil), navigationPath: $navigationPath)
//        .environment(FireChatViewModel())
//        .environment(FireAuthViewModel())
//}
