import PhotosUI
import SwiftUI
import MediaPlayer

struct FireChatDetailView: View {

    let userId:String
    var user: FireUserModel {
        userViewModel.allUsers.first { $0.id == userId } ?? FireUserModel(name: "Unknown")
    }
    @Environment(\.dismiss) var dismiss
    @Environment(FireChatViewModel.self) private var chatViewModel
    @Environment(FireAuthViewModel.self) private var authViewModel
    @Environment(FireMessageViewModel.self) private var messageViewModel
    @Environment(FireUserViewModel.self) private var userViewModel
    @State private var lastMessage : FireMessageModel? = nil
    @FocusState private var isTextFieldFocused: Bool
    @State private var isMediaSheetVisible: Bool = false
    @State var chatId: String?
    @State private var messageText: String = ""
    @State private var isProfileDetailPresented: Bool = false
    @State private var isProfileImagePresented: Bool = false
    @State private var isTyping: Bool?
    @State private var onlineStatus: Bool?
    @State private var chatExists: Bool? = nil
    @Binding var navigationPath: NavigationPath
    @Binding var chatImageDetailView : Bool
    @Binding var currentMessage: FireMessageModel?
    @State private var selectedMedia: MPMediaItem?
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var selectedVideos: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var showPreview = false


    // -------------------------------------- MARK: VIEW BODY ------------------------------------------------------------

    var body: some View {
        ZStack {
            VStack {
                ZStack {
                    backGroundImage
                    mainScrollChatsView
                        .onTapGesture {
                            dismissKeyboard()
                            withAnimation(.easeInOut) {
                                           isMediaSheetVisible = false
                                       }
                        }
                }
                inputMessageTabView
            }
            .navigationDestination(isPresented: $isProfileDetailPresented, destination: {
                ProfileDetailsView(user: user)
            }
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
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
            .onChange(of: messageViewModel.messages.last ){ _,newValue in
                lastMessage = newValue
            }
            .onChange(of: user.onlineStatus ) { _,newValue in
                onlineStatus = newValue
            }
            .onChange(of: user.isTyping ){ _,newValue in
                isTyping = newValue ?? false
            }
            .onChange(of: isTextFieldFocused ){ _,newValue in

                    userViewModel.updateUserTypingStatus(
                        userId: authViewModel.currentLoggedInUser?.id ?? "",
                        newStatus: newValue ? true : false
                    ) { error in
                        if let error = error {
                            print(error.localizedDescription)
                        }
                    }

            }
            .onDisappear {
                onDisappearFunctions()
            }
            //            profilePicOverlayZStack
            if showPreview, let image = capturedImage {
                            ImagePreviewView(
                                image: image,
                                onSend: {
                                    // 👉 Pass the image to your chat message logic here
                                    print("Sending image…")
                                    showPreview = false
                                    capturedImage = nil
                                },
                                onCancel: {
                                    showPreview = false
                                    capturedImage = nil
                                }
                            )
                            .transition(.move(edge: .bottom))
                            .zIndex(1)
                        }
        }
    }

    // ----------------------------------- MARK: HELPER FUNCTIONS---------------------------------------------------------
    private func onChangeOfOnlineStatusFunction(newValue: Bool?){

        print("ON CHANGE Online Status of the USER: \(String(describing: onlineStatus))")
    }
    private func onDisappearFunctions(){
        userViewModel.updateUserOnlineStatus(userId: authViewModel.currentLoggedInUser?.id ?? "", newStatus: false ){ error in
            if let error = error {
                print("Error updating user online status: \(error.localizedDescription)")
            }
        }
        print("DISAPPEAR Online Status of the USER: \(String(describing: onlineStatus))")
        chatId = ""
        lastMessage = nil
        messageViewModel.removeMessageListener()
        DispatchQueue.main.async {
            UITabBar.appearance().isHidden = false
        }
    }
    private func onAppearFunctions(){
        Task{
            await userViewModel.initializeData(loggedInUserId: user.id)
            chatExists = await chatViewModel.isThereChat(for: [authViewModel.currentLoggedInUser?.id ?? "", user.id])
            if chatExists == true {
                chatId = await chatViewModel.loadChatId(for: [authViewModel.currentLoggedInUser?.id ?? "", user.id])
                messageViewModel.setupMessageListener(for: chatId ?? "Error")
                await messageViewModel.fetchAllMessages(for: chatId ?? "Error")
            }
            userViewModel.updateUserOnlineStatus(userId: authViewModel.currentLoggedInUser?.id ?? "Error", newStatus: true)
            { error in
                if let error = error {
                    print("Error updating user online status: \(error.localizedDescription)")
                }
            }
            onlineStatus = user.onlineStatus
            isTyping = user.isTyping ?? false
            print("Online Status of the USER: \(String(describing: onlineStatus))")
            lastMessage = messageViewModel.messages.last
            if isTextFieldFocused {
                isTyping = true
            }
        }
    }
    private func sendMessage() async {
        Task{
            guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            if chatExists == false {
                await chatViewModel.createNewChat(for: [authViewModel.currentLoggedInUser?.id ?? "", user.id])
                chatId = await chatViewModel.loadChatId(for: [authViewModel.currentLoggedInUser?.id ?? "", user.id])
                messageViewModel.setupMessageListener(for: chatId ?? "Error")
                print("THE CHAT ID ---- > \(chatId ?? "NO CHATID HERE ---❌---")")
            }
            await messageViewModel.sendTextMessage(chatId: chatId ?? "" , currentUserId: authViewModel.currentLoggedInUser?.id ?? "", otherUserId: user.id, content: messageText)
            messageText = ""
        }
        dismissKeyboard()
    }
    private func dismissKeyboard() {
        if isTyping ?? false {
            isTyping = false
        }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    private func sendImage(_ image: UIImage) async {
        guard let currentUserId = authViewModel.currentLoggedInUser?.id else { return }

        Task {
            if chatExists == false {
                await chatViewModel.createNewChat(for: [authViewModel.currentLoggedInUser?.id ?? "", user.id])
                chatId = await chatViewModel.loadChatId(for: [authViewModel.currentLoggedInUser?.id ?? "", user.id]) ?? ""
                print("THE CHAT ID ---- > \(chatId ?? "" )")
            }
            await messageViewModel.sendImageMessage(
                chatId: chatId ?? "" ,
                currentUserId: currentUserId,
                otherUserId: user.id,
                imageData: image
            )
        }
    }
    private func sendVideo(_ videoData: Data) async {
        guard let currentUserId = authViewModel.currentLoggedInUser?.id else { return }

        Task {

            if chatExists == false {
                await chatViewModel.createNewChat(for: [authViewModel.currentLoggedInUser?.id ?? "", user.id])
                chatId = await chatViewModel.loadChatId(for: [authViewModel.currentLoggedInUser?.id ?? "", user.id])
                print("THE CHAT ID ---- > \(chatId ?? "NO CHATID HERE ---❌---")")
            }
            await messageViewModel.sendVideoMessage(
                chatId: chatId ?? "",
                currentUserId: currentUserId,
                otherUserId: user.id,
                videoData: videoData
            )
        }
    }

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
    //   ---------------------------------------------------------------------------------------------------------------------------------------------------------

    private var renderMessages : some View{
        VStack{
            let date : Date = user.createdDate ?? .now
            Group{
                Text(timeString(from: date))
                    .padding()
                    .frame( alignment: .center)
                    .background(Color.white.opacity(0.9))
                Text(" 🔐  Messages and calls are end-to-end encrypted. No one outside of this chat, not even WhatsApp, can read or listen to them. Tap to learn more.")
                    .frame(maxWidth: 300  , alignment: .center)
                    .padding()
                    .background(Color.yellow.opacity(0.5))
            }.font(.caption)
                .foregroundColor(.secondary)
                .cornerRadius(12)
                .padding(.bottom)
            ForEach(messageViewModel.messages) { message in
                FireChatBubble(
                    message: message,
                    currentUserId: authViewModel.currentLoggedInUser?.id ?? "Error",
                    userId: user.id,
                    chatImageDetailView: $chatImageDetailView,
                    chatId: $chatId, currentMessage: $currentMessage,
                    onReply: {
                        messageText = "Replying to: \"\(message.content)\"\n"
                    },
                    onForward: {
                        print("Forward message: \(message.content)")
                    },
                    onDelete: {
                        Task{
                            await messageViewModel.deleteMessage(for: message.id)
                            print("Message deleted! for ---- ♻️ -- \(message.id)")
                        }
                    }
                )
                .id(message.id)
            }
        }
    }
    // MARK: BG IMG
    private var backGroundImage: some View {
        Image("bgChats")
            .resizable()
            .scaleEffect(1.4)
            .opacity(0.35)
    }
    // MARK: BACK BUTTON NAV --- NAVV ITEMS
    private var backButton: some View {
        Button(action: {
            navigationPath.removeLast()
            print("Back button pressed!")
        })
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
                    withAnimation(.smooth ) {
                        renderMessages
                    }
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
            .onChange(of: isTyping ?? false) { _, newValue in
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

    private var inputMessageTabView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isMediaSheetVisible.toggle()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.gray.opacity(0.7))
                }

                TextField("Message", text: $messageText)
                    .focused($isTextFieldFocused)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)

                if messageText.isEmpty {
                    HStack(spacing: 16) {
                        Button {
                            // Camera action
                            showCamera = true
                        } label: {
                            Image(systemName: "camera")
                                .font(.system(size: 22))
                                .foregroundColor(.gray.opacity(0.7))
                        }

                        VoiceRecordButton { audioURL, duration in
                            Task {
                                await messageViewModel.sendVoiceMessage(
                                    chatId: chatId ?? "Error",
                                    currentUserId: authViewModel.currentLoggedInUser?.id ?? "Error",
                                    otherUserId: user.id,
                                    audioFileURL: audioURL,
                                    duration: duration
                                )
                            }
                        }
                    }
                } else {
                    Button(action: { Task { await sendMessage() } }) {
                        Circle()
                            .fill(Color.green) // WhatsApp green
                            .frame(width: 38, height: 38)
                            .overlay(
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .offset(x: 1)
                            )
                    }
                }
            }
            .padding(.horizontal)

            .padding(.bottom, 5)

            if isMediaSheetVisible {
                mediaPickerSheet
//                    .transition(.move(edge: .bottom))
            }
        }
        .background(Color.white)
//        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: -1)
    }

    private var mediaPickerSheet: some View {
        VStack(spacing: 0) {
            // Handle indicator
//            Rectangle()
//                .fill(Color(.systemGray4))
//                .frame(width: 40, height: 4)
//                .cornerRadius(2)
//                .padding(.top, 8)
//                .padding(.bottom, 20)

            // Grid layout
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 24) {
                // Document button
                mediaSheetButton(iconName: "doc.fill", label: "Document", color: Color.purple)

                // Camera button
                Button {
                    showCamera = true
                } label: {
                    mediaSheetButtonView(iconName: "camera.fill", label: "Camera", color: Color.red.opacity(0.8))
                }

                // Image Gallery button
                PhotosPicker(
                    selection: $selectedImages,
                    maxSelectionCount: 10,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    mediaSheetButtonView(iconName: "photo.fill", label: "Images", color: Color.cyan)
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
                        isMediaSheetVisible = false
                    }
                }
                PhotosPicker(
                    selection: $selectedVideos,
                                            maxSelectionCount: 2,
                                            matching: .videos,
                                            photoLibrary: .shared()
                ) {
                    mediaSheetButtonView(iconName: "photo.fill", label: "Videos", color: Color.teal)
                }
                .onChange(of: selectedVideos) { _, newItems in
                    Task {
                        for item in newItems {
                            if let data = try? await item.loadTransferable(type: Data.self) {
                                await sendVideo(data)
                            }
                        }
                        selectedVideos.removeAll()
                    }
                }

                // Audio button
                mediaSheetButton(iconName: "music.note", label: "Audio", color: Color.orange)

                // Location button
                mediaSheetButton(iconName: "location.fill", label: "Location", color: Color.green)

                // Contact button
                mediaSheetButton(iconName: "person.fill", label: "Contact", color: Color.indigo)

                // Poll button
                mediaSheetButton(iconName: "chart.bar.fill", label: "Poll", color: Color.pink)
            }
            .padding(.horizontal, 20)
//            .padding(.bottom, 30)
        }
//        .padding(.bottom, 16)
        .background(
//            RoundedRectangle(cornerRadius: 20)
//                .fill(Color.white)
//                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
            Color.white
        )
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                capturedImage = image
                showPreview = true
            }
        }
    }

    // Helper function to create consistent media sheet buttons
    private func mediaSheetButton(iconName: String, label: String, color: Color) -> some View {
        Button {
            isMediaSheetVisible = false
        } label: {
            mediaSheetButtonView(iconName: iconName, label: label, color: color)
        }
    }

    // Helper function for the button view
    private func mediaSheetButtonView(iconName: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 58, height: 58)

                Image(systemName: iconName)
                    .font(.system(size: 26))
                    .foregroundColor(.white)
            }

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.primary)
        }
    }

    private var typingIndicator: some View {
        Group{
            if (isTyping ?? false && user.id != authViewModel.currentLoggedInUser?.id ) {
                HStack {
                    ChatTypingIndicator()
                    Spacer()
                }
                .padding(.leading)
                .transition(.opacity)
                .id("TypingIndicator")
            }
        }
    }
    // MARK: PROFILE IMAGE

    private var profileImage: some View {
        Group{
            if let imageUrlString = user.imageUrl, let imageUrl = URL(string: imageUrlString),!imageUrlString.hasSuffix(".svg") {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 32, height: 32)
                    case .success(let image):
                        withAnimation(.smooth){
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        }
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
