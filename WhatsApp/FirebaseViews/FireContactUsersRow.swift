
import SwiftUI

struct FireContactUsersRow: View {
    let user: FireUserModel

    @State private var lastMessage: FireMessageModel?
    @Environment(FireChatViewModel.self) private var chatViewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var profileImageURLString: String? = ""
    @Binding var navigationPath: NavigationPath

    var body: some View {
        HStack {
                    userProfilePictureView
                    userProfileNameandContent
                    Spacer()
                }
                .padding(.vertical, 5)
                .onTapGesture {
                    navigationPath.append(user)
                }
        .buttonStyle(.plain)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                profileImageURLString = user.imageUrl
            }
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
    @Previewable @State var navigationPath: NavigationPath = NavigationPath()
    FireContactUsersRow(user: FireUserModel(id: "123", phoneNumber: "99", name: "Test User", imageUrl: nil), navigationPath: $navigationPath)
        .environment(FireChatViewModel())
        .environment(AuthViewModel())
}
