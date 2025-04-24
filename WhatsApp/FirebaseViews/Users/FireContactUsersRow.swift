
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
    @Environment(UtilityClass.self) private var utilityVM
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
            Text(utilityVM.timeString(from: date))
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
                        DefaultProfileImage(size: 50)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50,height: 50)
                            .clipShape(Circle())

                    case .failure:
                        DefaultProfileImage(size: 50)
                    @unknown default:
                        EmptyView()
                            .frame(width: 50,height: 50)
                    }
                }

            }
            else{
                DefaultProfileImage(size: 50)
            }
        }
    }

}

//#Preview {
//    @Previewable @State var navigationPath: NavigationPath = NavigationPath()
//    FireContactUsersRow(user: FireUserModel(id: "123", phoneNumber: "99", name: "Test User", imageUrl: nil), navigationPath: $navigationPath)
//        .environment(FireChatViewModel())
//        .environment(FireAuthViewModel())
//}
