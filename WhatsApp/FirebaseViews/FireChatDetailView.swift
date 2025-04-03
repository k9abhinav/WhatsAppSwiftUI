import PhotosUI
import SwiftUI

struct FireChatDetailView: View {

    let user: FireUserModel
    @Environment(FireChatViewModel.self) private var chatViewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(FireMessageViewModel.self) private var messageViewModel
    @Environment(FireUserViewModel.self) private var userViewModel
    @Environment(\.presentationMode) private var presentationMode
    @State private var lastMessage : FireMessageModel? = nil
    @FocusState private var isTextFieldFocused: Bool
    @State private var messageText: String = ""
    @State private var isProfileDetailPresented: Bool = false
    @State private var isProfileImagePresented: Bool = false
    @State private var isTyping: Bool = false
    @State private var onlineStatus: Bool? = nil
    @State private var chatExists: Bool? = nil
    @Binding var navigationPath: NavigationPath
    @State private var selectedImages: [PhotosPickerItem] = []
    // -------------------------------------- MARK: VIEW BODY ------------------------------------------------------------

    var body: some View {
        ZStack {
            VStack {
                ZStack {
                    backGroundImage
                    mainScrollChatsView
                }
                inputMessageTabBar
                    
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $isProfileDetailPresented, destination: {
                ProfileDetailsView(user: user)
            })
            .navigationDestination(for: FireUserModel.self) { user in
                ProfileDetailsView(user: user)
            }// fix
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) { backButton ; topLeftNavItems }
                ToolbarItem(placement: .topBarTrailing) { topRightNavItems }
            }
            .toolbarBackground(.white, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
            .onAppear {
                onAppearFunctions()
            }
            .onChange(of: onlineStatus) {
                onChangeOfOnlineStatusFunction()
            }
            .onDisappear {
                onDisappearFunctions()
            }
            profilePicOverlayZStack
        }
    }

    // ----------------------------------- MARK: HELPER FUNCTIONS---------------------------------------------------------
    private func onChangeOfOnlineStatusFunction(){
        Task {
            await authViewModel.loadCurrentUser()
        }
        onlineStatus = user.onlineStatus
    }
    private func onDisappearFunctions(){
        userViewModel.updateUserOnlineStatus(userId: authViewModel.currentLoggedInUser?.id ?? "", newStatus: false ){ error in
            if let error = error {
                print("Error updating user online status: \(error.localizedDescription)")
            }
        }
        messageViewModel.removeMessageListener()
        DispatchQueue.main.async {
            UITabBar.appearance().isHidden = false
        }
    }
    private func onAppearFunctions(){
        Task{
            chatExists = await chatViewModel.isThereChat(for: [authViewModel.currentLoggedInUser?.id ?? "", user.id])
            if chatExists == true {
                await chatViewModel.loadChatId(for: [authViewModel.currentLoggedInUser?.id ?? "", user.id])
                print("THE CHAT ID ---- > \(String(describing: chatViewModel.currentChatId ))")
            } else{
                await chatViewModel.createNewChat(for: [authViewModel.currentLoggedInUser?.id ?? "", user.id])
                await chatViewModel.loadChatId(for: [authViewModel.currentLoggedInUser?.id ?? "", user.id])
                print("THE CHAT ID ---- > \(String(describing: chatViewModel.currentChatId ))")
            }
            messageViewModel.setupMessageListener(for: chatViewModel.currentChatId ?? "Error")
            await messageViewModel.fetchAllMessages(for: chatViewModel.currentChatId ?? "Error")
            userViewModel.updateUserOnlineStatus(userId: authViewModel.currentLoggedInUser?.id ?? "", newStatus: true){ error in
                if let error = error {
                    print("Error updating user online status: \(error.localizedDescription)")
                }
            }
            await authViewModel.loadCurrentUser()
            onlineStatus = user.onlineStatus
            lastMessage = messageViewModel.messages.last
            if isTextFieldFocused {
                isTyping = true
            }
        }
    }
    private func sendMessage() async {
        Task{
            guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            await messageViewModel.sendTextMessage(chatId: chatViewModel.currentChatId ?? "" , currentUserId: authViewModel.currentLoggedInUser?.id ?? "", otherUserId: user.id, content: messageText)
            messageText = ""
        }
        dismissKeyboard()
    }

    private func dismissKeyboard() {
        isTyping = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    private func sendImage(_ image: UIImage) async {
        guard let currentUserId = authViewModel.currentLoggedInUser?.id else { return }
        Task {
                await messageViewModel.sendImageMessage(
                    chatId: chatViewModel.currentChatId ?? "",
                    currentUserId: currentUserId,
                    otherUserId: user.id,
                    imageData: image
                )
            }
    }
    //   ---------------------------------------------------------------------------------------------------------------------------------------------------------

    private var renderMessages : some View{
        ForEach(messageViewModel.messages) { message in
            FireChatBubble(
                message: message,
                currentUserId: authViewModel.currentLoggedInUser?.id ?? "Error",
                onReply: {
                    // Handle reply action
                    // For example, you might want to quote the message and focus the text field
                    messageText = "Replying to: \"\(message.content)\"\n"
                    //                                isTextFieldFocused = true
                },
                onForward: {
                    // Handle forward action
                    // This could open a user selection sheet to forward the message to
                    print("Forward message: \(message.content)")
                },
                onDelete: {
                    // Handle delete action
                    Task {
                        //
                    }
                }
            )
            .id(message.id)
        }
    }
    // MARK: BG IMG
    private var backGroundImage: some View {
        Image("bgChats")
            .resizable()
            .scaleEffect(1.4)
            .opacity(0.5)
    }
    // MARK: BACK BUTTON NAV --- NAVV ITEMS
    private var backButton: some View {
        Button(action: { navigationPath = NavigationPath() })
        {  Image(systemName: "arrow.backward")  }
    }

    private var topLeftNavItems: some View {
        HStack {
            profileImage
                .onTapGesture {
                    isProfileImagePresented.toggle()
                }
            VStack(alignment: .leading) {
                Text(user.name).font(.headline)
                if(authViewModel.currentLoggedInUser?.id ?? "" == user.id){
                    Text(user.aboutInfo ?? "ERROR").font(.caption).foregroundColor(.gray)
                }else{
                    Text(onlineStatus ?? false ? "Online" : "Offline").font(.caption).foregroundColor(.gray)
                }
            }
            .onTapGesture {
                isProfileDetailPresented.toggle()
            }
        }
    }

    private var topRightNavItems: some View {
        HStack {
            Button(action: { print("Video call tapped") }) { Image(systemName: "video") }
            Button(action: { print("Phone call tapped") }) { Image(systemName: "phone") }
        }
    }
    // MARK: SCROLLVIEW
    private var mainScrollChatsView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(spacing: 10, pinnedViews: []) {
                    renderMessages
                    typingIndicator
                }
            }
            .scrollIndicators(.hidden)
            .onAppear {
                DispatchQueue.main.async {
                    if let lastMessage = lastMessage {
                        scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: messageViewModel.messages.count ) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    if let lastMessage = lastMessage {
                        withTransaction(Transaction(animation: nil)) {
                            scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            .onChange(of: isTextFieldFocused) { _, isFocused in
                if isFocused {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let lastMessage = lastMessage {
                            scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            .onChange(of: isTyping) { _, newValue in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {

                    if newValue {
                        scrollProxy.scrollTo("TypingIndicator", anchor: .bottom)
                    } else if let lastMessage = lastMessage {
                        scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }

                }
            }

        }
    }
    // MARK: PROFILE PIC OVERLAY
    private var profilePicOverlayZStack: some View {
        Group {
            if isProfileImagePresented {
                ProfilePicOverlay(user: user) {
                    withAnimation(.easeInOut(duration: 0.3)) { isProfileImagePresented = false }
                }
                .transition(.opacity)
            }
        }
    }
    // MARK: Message Tab Bar
    private var inputMessageTabBar: some View {
        HStack(spacing: 12) {
            PhotosPicker(
                selection: $selectedImages,
                maxSelectionCount: 2, // Allow multiple images
                matching: .images,
                photoLibrary: .shared()
            ) {
                Image(systemName: "plus")
                    .font(.system(size: 22))
                    .foregroundColor(.gray)
            }
            .onChange(of: selectedImages) { _, newItems in
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await sendImage(image)
                        }
                    }
                    selectedImages.removeAll()
                }
            }
            TextField("Message", text: $messageText)
                .focused($isTextFieldFocused)
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
            Button(action: { Task { await sendMessage() }}) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.customGreen)
            }
            .disabled(messageText.isEmpty)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 5)
        .background(Color.white)
        .ignoresSafeArea()
    }
    private var typingIndicator: some View {
        Group{
            if (isTyping && user.id != authViewModel.currentLoggedInUser?.id ) {
                HStack {
                    ChatTypingIndicator()
                    Spacer()
                }
                .padding(.leading, 20)
                .transition(.opacity)
                .id("TypingIndicator")
            }
        }
    }
    // MARK: PROFILE IMAGE

    private var profileImage: some View {
        Group{
            // Profile Image
            if let imageUrlString = user.imageUrl, let imageUrl = URL(string: imageUrlString),!imageUrlString.hasSuffix(".svg") {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 32, height: 32)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    case .failure:
                        defaultProfileImage
                    @unknown default:
                        EmptyView()
                            .frame(width: 32, height: 32)
                    }
                }
            } else {
                defaultProfileImage
            }
        }
    }
    // MARK: DEFAULT PROFILE IMAGE
    private var defaultProfileImage: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFill()
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            .foregroundColor(.gray)
    }
}

#Preview {

}
