
import SwiftUI
import PhotosUI

struct FireChatRow: View {

    let userId:String
    var user: FireUserModel {
        userViewModel.allUsers.first { $0.id == userId } ?? FireUserModel(name: "Unknown")
    }
    @Binding var currentUser: FireUserModel?
    @Binding var isProfilePicPresented : Bool
    @Binding var currentProfileImageData: Data?
    @Environment(FireChatViewModel.self) private var chatViewModel
    @Environment(FireMessageViewModel.self) private var messageViewModel
    @Environment(FireUserViewModel.self) private var userViewModel
    @Environment(FireAuthViewModel.self) private var authViewModel
    @Environment(UtilityClass.self) private var utilityVM
    @State private var lastMessageContent : String?
    @State private var lastSeenTimeStamp: Date? = nil
    @Binding var navigationPath: NavigationPath
    @State var imageURLData: Data?
    var body: some View {
        Button {
            navigationPath.append(user)
        } label: {
                   HStack {
                       profilePicViewButton
                       userProfileNameandContent
                   }
                   .padding(.vertical, 5)
               }
        .buttonStyle(.plain)
        .onAppear { onAppearFunctions() }
        .task{
            guard let url = URL(string: user.imageUrl ?? "") else {
                print("No URL provided for image")
                return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                DispatchQueue.main.async {
                    imageURLData = data
                }

            } catch {
                print("Failed to load image data: \(error.localizedDescription)")
            }
        }
        .onChange(of: chatViewModel.triggeredUpdate) { _,newValue in
            print(newValue.description)
            if newValue {
                fetchLastMessage()
            }
        }
        .onDisappear { onDisappearFunctions() }
    }
    
    // MARK: SUB-COMPONENTS -----
    private var profilePicViewButton: some View {
        Button(
            action: {
                currentUser = user
                currentProfileImageData = imageURLData
                isProfilePicPresented.toggle()
            },
            label: {   ProfileAsyncImageView(size: 50, imageUrlString: user.imageUrl ) } )
        .buttonStyle(PlainButtonStyle())
    }
    private var userLastSeenTime: some View {
        VStack {
            let date: Date = lastSeenTimeStamp ?? .distantPast
            Text(utilityVM.timeString(from: date))
                .font(.caption)
                .fontWeight(.light)
                .foregroundStyle(.gray.opacity(0.8))
        }
    }
    private var userProfileNameandContent: some View {
        Button(action: {
            navigationPath.append(user)
        }, label: {
            VStack(alignment: .leading,spacing: 6) {
                HStack {
                    Text(user.name)
                        .font(.headline)
                        .foregroundStyle(.black)
                    if user.id == authViewModel.currentLoggedInUser?.id {
                        Text("(You)")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    userLastSeenTime
                }

                HStack(spacing:12 ){
                    Image("doubleCheck")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 5, height: 5)
                        .scaleEffect(3.5)

                    Text(lastMessageContent ?? "No Message")
                        .font(.subheadline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(.gray)
                    Spacer()
                    ZStack {
                        Image(systemName: "circlebadge.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(Color.customGreen)
                            .frame(width: 20, height: 20)
                        Text("")
                            .foregroundStyle(.white)
                            .font(.caption)
                            .fontWeight(.semibold)

                    }.padding(.top,3)
                }
                .padding(.leading,5)
            }
        })

    }
    
    // MARK: HELPER FUNCTIONS -------------------------------

    
    private func onAppearFunctions(){
        chatViewModel.setupChatListener(currentUserId: authViewModel.currentLoggedInUser?.id ?? "")
        fetchLastMessage()
    }
    private func fetchLastMessage() {
        Task { @MainActor in
            let details = await chatViewModel.fetchLastMessageDetails(for: [authViewModel.currentLoggedInUser?.id ?? "", user.id])
            if details.timestamp != lastSeenTimeStamp || details.content != lastMessageContent {
                lastMessageContent = details.content
                lastSeenTimeStamp = details.timestamp
            }
            print("DEBUG IN FIRE CHAT ROW : - Content: \(String(describing: lastMessageContent)) \n Timestamp: \(String(describing: lastSeenTimeStamp))")
        }
    }
    private func onDisappearFunctions(){
                chatViewModel.removeChatListener() 
    }

}

//#Preview {
//    @Previewable @State var navigationPath: NavigationPath = NavigationPath()
//    FireChatRow(user: FireUserModel(id: "123", phoneNumber: "9900",  name: "Test User", imageUrl: nil),
//                currentUser: .constant(nil),
//                isProfilePicPresented: .constant(false), navigationPath: $navigationPath)
//    .environment(FireChatViewModel())
//    .environment(AuthViewModel())
//}
