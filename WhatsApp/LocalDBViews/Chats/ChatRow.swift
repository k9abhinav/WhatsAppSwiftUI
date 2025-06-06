
import SwiftUI
import SwiftData

struct ChatRow: View {

    let user: User
    @State private var isProfilePicPresented = false
    @Environment(UtilityClass.self) private var utilityVM
    @Bindable var localChatsVM : ChatsViewModel
    var body: some View {

        NavigationLink( destination: ChatDetailView(user:user, localChatsVM: localChatsVM) )
        {
            HStack {
                Button(
                    action: { isProfilePicPresented.toggle() },
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
    }
    // MARK: SUB-COMPONENTS -----
    private var userLastSeenTime: some View {
        VStack {
            let date: Date = user.lastChatMessage?.timestamp ??  .now
            Text(utilityVM.timeString(from: date))
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

                Text(user.lastChatMessage?.content ?? "")
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.gray)
            }
            .padding(.leading,5)
        }
    }
    private var userProfilePictureView: some View {
        Group{
            if let imageData = user.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {

}
