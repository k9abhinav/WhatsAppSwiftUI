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
            userViewModel.updateUserOnlineStatus(userId: authViewModel.currentLoggedInUser?.id ?? "", newStatus: true){ error in
                if let error = error {
                    print("Error updating user online status: \(error.localizedDescription)")
                }
            }
            await authViewModel.loadCurrentUser()
            onlineStatus = user.onlineStatus
        }
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
        }
    }
    private func sendMessage() async {
        Task{
            guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            await messageViewModel.sendTextMessage(chatId: chatViewModel.currentChatId ?? "" , currentUserId: authViewModel.currentLoggedInUser?.id ?? "", otherUserId: user.id, content: messageText)
            messageText = ""
        }

        if isTextFieldFocused {
            isTyping = true
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        isTyping = false
    }

    //   ---------------------------------------------------------------------------------------------------------------------------------------------------------

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
                Text(onlineStatus ?? false ? "Online" : "Offline").font(.caption).foregroundColor(.gray)
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
                    ForEach( messageViewModel.messages ) { message in
                        FireChatBubble(message: message , currentUserId: authViewModel.currentLoggedInUser?.id ?? "Error" )
                            .id(message.id)
                    }

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
                selection: .constant( nil ) ,
                matching: .images,
                photoLibrary: .shared()
            )
            {
                Image(systemName: "plus")
                    .font(.system(size: 22))
                    .foregroundColor(.gray)
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
    // MARK: PROFILE IMAGE
    private var profileImage: some View {
        AsyncImage(url: URL(string: user.imageUrl ?? "")) { phase in
            switch phase {
            case .empty:
                defaultProfileImage
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            default:
                ProgressView()
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
