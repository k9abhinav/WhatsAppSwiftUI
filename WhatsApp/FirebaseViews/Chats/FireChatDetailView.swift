import PhotosUI
import SwiftUI
import MediaPlayer

struct FireChatDetailView: View {
    // MARK: - Properties
    let userId: String

    @Environment(\.dismiss) var dismiss
    @Environment(FireChatViewModel.self) private var chatViewModel
    @Environment(FireAuthViewModel.self) private var authViewModel
    @Environment(FireMessageViewModel.self) private var messageViewModel
    @Environment(FireUserViewModel.self) private var userViewModel
    @Environment(UtilityClass.self) private var utilityVM

    @FocusState private var isTextFieldFocused: Bool
    @Binding var imageURLData: Data?
    @Binding var navigationPath: NavigationPath
    @Binding var chatImageDetailView: Bool
    @Binding var currentChatImageData: Data?

    // Consolidated state variables
    @State private var uiState = UIState()
    @State private var chatState = ChatState()
    @State private var mediaState = MediaState()

    // Computed properties
    var user: FireUserModel {
        userViewModel.allUsers.first { $0.id == userId } ?? FireUserModel(name: "Unknown~User")
    }

    var currentUserId: String {
        authViewModel.currentLoggedInUser?.id ?? ""
    }

    // MARK: - View Body
    var body: some View {
        ZStack {
            VStack {
                ZStack {
                    backGroundImage
                    mainScrollChatsView
                        .onTapGesture {
                            dismissKeyboard()
                            withAnimation(.easeInOut) {
                                uiState.isMediaSheetVisible = false
                            }
                        }
                }
                inputMessageTabView
            }
            .navigationDestination(
                isPresented: $uiState.isProfileDetailPresented,
                destination: {
                    ProfileDetailsView(
                        userName: user.name,
                        userOnlineStatus: user.onlineStatus ?? false,
                        userImageData: $imageURLData 
                    )
                }
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) { backButton; topLeftNavItems }
                ToolbarItem(placement: .topBarTrailing) { topRightNavItems }
            }
            .toolbarBackground(.white, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
            .onAppear { Task { await onAppearFunctions() } }
            .onDisappear { onDisappearFunctions() }
            .task{
                if uiState.isTyping{
                    uiState.isMediaSheetVisible = false
                }
            }
            .onChange(of: messageViewModel.messages.last) { _, newValue in
                chatState.lastMessage = newValue
            }
            .onChange(of: user.onlineStatus) { _, newValue in
                uiState.onlineStatus = newValue
            }
            .onChange(of: user.isTyping) { _, newValue in
                uiState.isTyping = newValue ?? false
            }
            .onChange(of: isTextFieldFocused) { _, newValue in
                uiState.isMediaSheetVisible = false
                updateTypingStatus(isTyping: newValue)
            }

            // Image preview overlay
            if uiState.showPreview, let image = mediaState.capturedImage {
                ImagePreviewView(
                    image: image,
                    onSend: {
                        Task { await sendImage(image) }
                        uiState.showPreview = false
                        mediaState.capturedImage = nil
                    },
                    onCancel: {
                        uiState.showPreview = false
                        mediaState.capturedImage = nil
                    }
                )
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }

            // Profile picture overlay
            if uiState.isProfileImagePresented {
                ProfilePicOverlay(imageData: imageURLData, username: user.name) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        uiState.isProfileImagePresented = false
                    }
                }
                .transition(.opacity)
            }
        }
    }

    // MARK: - Helper Methods
    private func onAppearFunctions() async {
        await userViewModel.initializeData(loggedInUserId: user.id)
        chatState.chatExists = await chatViewModel.isThereChat(for: [currentUserId, user.id])

        if chatState.chatExists == true {
            chatState.chatId = await chatViewModel.loadChatId(for: [currentUserId, user.id])
            messageViewModel.setupMessageListener(for: chatState.chatId ?? "Error")
            await messageViewModel.fetchAllMessages(for: chatState.chatId ?? "Error")
        }

        userViewModel.updateUserOnlineStatus(userId: currentUserId, newStatus: true) { error in
            if let error = error {
                print("Error updating user online status: \(error.localizedDescription)")
            }
        }

        uiState.onlineStatus = user.onlineStatus
        uiState.isTyping = user.isTyping ?? false
        chatState.lastMessage = messageViewModel.messages.last
    }

    private func onDisappearFunctions() {
        userViewModel.updateUserOnlineStatus(userId: currentUserId, newStatus: false) { error in
            if let error = error {
                print("Error updating user online status: \(error.localizedDescription)")
            }
        }

        chatState.chatId = ""
        chatState.lastMessage = nil
        messageViewModel.messages.removeAll()
        messageViewModel.removeMessageListener()

        DispatchQueue.main.async {
            UITabBar.appearance().isHidden = false
        }
    }

    private func updateTypingStatus(isTyping: Bool) {
        userViewModel.updateUserTypingStatus(
            userId: currentUserId,
            newStatus: isTyping
        ) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }

    private func dismissKeyboard() {
        if uiState.isTyping {
            uiState.isTyping = false
        }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Message Actions
    private func sendMessage() async {
        guard !chatState.messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        if chatState.chatExists == false {
            await createChatIfNeeded()
        }

        await messageViewModel.sendTextMessage(
            chatId: chatState.chatId ?? "",
            currentUserId: currentUserId,
            otherUserId: user.id,
            content: chatState.messageText
        )

        chatState.messageText = ""
        dismissKeyboard()
    }

    private func sendImage(_ image: UIImage) async {
        await createChatIfNeeded()
        await messageViewModel.sendImageMessage(
            chatId: chatState.chatId ?? "",
            currentUserId: currentUserId,
            otherUserId: user.id,
            imageData: image
        )
    }

    private func sendVideo(_ videoData: Data) async {
        await createChatIfNeeded()
        await messageViewModel.sendVideoMessage(
            chatId: chatState.chatId ?? "",
            currentUserId: currentUserId,
            otherUserId: user.id,
            videoData: videoData
        )
    }

    private func createChatIfNeeded() async {
        if chatState.chatExists == false {
            await chatViewModel.createNewChat(for: [currentUserId, user.id])
            chatState.chatId = await chatViewModel.loadChatId(for: [currentUserId, user.id])
            messageViewModel.setupMessageListener(for: chatState.chatId ?? "")
            chatState.chatExists = true
        }
    }

    // MARK: - UI Components
    private var backGroundImage: some View {
        Image("bgChats")
            .resizable()
            .scaleEffect(1.4)
            .opacity(0.35)
    }

    private var backButton: some View {
        Button(action: { navigationPath.removeLast() }) {
            Image(systemName: "arrow.backward")
        }
    }

    private var topLeftNavItems: some View {
        HStack {
            ProfileImageView(size: 32, imageData: $imageURLData)
                .onTapGesture { uiState.isProfileImagePresented.toggle() }

            VStack(alignment: .leading) {
                Text(user.name).font(.headline)

                if currentUserId == user.id {
                    Text(user.aboutInfo ?? "ERROR").font(.caption).foregroundColor(.gray)
                } else {
                    Text(uiState.onlineStatus ?? false ? "Online" : "Offline")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .onTapGesture { uiState.isProfileDetailPresented.toggle() }
        }
    }

    private var topRightNavItems: some View {
        HStack {
            Button(action: { }) { Image(systemName: "video") }
            Button(action: { }) { Image(systemName: "phone") }
        }
    }

    // MARK: - Chat Content
    private var mainScrollChatsView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    withAnimation(.smooth) {
                        renderMessages
                    }
                    typingIndicator
                }
            }
            .scrollIndicators(.hidden)
            .onAppear {
                scrollToLastMessage(using: scrollProxy)
            }
            .onChange(of: messageViewModel.messages.count) { _, _ in
                scrollToLastMessage(using: scrollProxy, delay: 0.05)
            }
            .onChange(of: isTextFieldFocused) { _, isFocused in
                if isFocused {
                    scrollToLastMessage(using: scrollProxy, delay: 0.1)
                }
            }
            .onChange(of: uiState.isTyping) { _, newValue in
                scrollToAppropriateItem(using: scrollProxy, isTyping: newValue)
            }
        }
    }

    private func scrollToLastMessage(using proxy: ScrollViewProxy, delay: Double = 0) {
        guard let lastMessage = chatState.lastMessage else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withTransaction(Transaction(animation: nil)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }

    private func scrollToAppropriateItem(using proxy: ScrollViewProxy, isTyping: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if isTyping {
                proxy.scrollTo("TypingIndicator", anchor: .bottom)
            } else if let lastMessage = chatState.lastMessage {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }

    private var renderMessages: some View {
        VStack {
            let date: Date = user.createdDate ?? .now

            Group {
                Text(utilityVM.timeString(from: date))
                    .padding()
                    .background(Color.white.opacity(0.9))

                Text(" 🔐  Messages and calls are end-to-end encrypted. No one outside of this chat, not even WhatsApp, can read or listen to them. Tap to learn more.")
                    .frame(maxWidth: 300, alignment: .center)
                    .padding()
                    .background(Color.yellow.opacity(0.5))
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .cornerRadius(12)
            .padding(.bottom)

            ForEach(messageViewModel.messages) { message in
                FireChatBubble(
                    message: message,
                    currentUserId: currentUserId,
                    userId: user.id,
                    chatImageDetailView: $chatImageDetailView,
                    chatId: $chatState.chatId,
                    currentChatImageData: $currentChatImageData,
                    onReply: {
                        chatState.messageText = "Replying to: \"\(message.content)\"\n"
                    },
                    onForward: { },
                    onDelete: {
                        Task { await messageViewModel.deleteMessage(for: message.id) }
                    }
                )
                .id(message.id)
            }
        }
    }

    private var typingIndicator: some View {
        Group {
            if uiState.isTyping && user.id != currentUserId {
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

    // MARK: - Input View
    private var inputMessageTabView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        uiState.isMediaSheetVisible.toggle()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.gray.opacity(0.7))
                }

                TextField("Message", text: $chatState.messageText)
                    .focused($isTextFieldFocused)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)

                if chatState.messageText.isEmpty {
                    HStack(spacing: 16) {
                        Button {
                            uiState.showCamera = true
                        } label: {
                            Image(systemName: "camera")
                                .font(.system(size: 22))
                                .foregroundColor(.gray.opacity(0.7))
                        }

                        VoiceRecordButton { audioURL, duration in
                            Task {
                                await createChatIfNeeded()
                                await messageViewModel.sendVoiceMessage(
                                    chatId: chatState.chatId ?? "",
                                    currentUserId: currentUserId,
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
                            .fill(Color.green)
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

            if uiState.isMediaSheetVisible {
                mediaPickerSheet
            }
        }
        .background(Color.white)
        .sheet(isPresented: $uiState.showCamera) {
            CameraPicker { image in
                mediaState.capturedImage = image
                uiState.showPreview = true
            }
        }
    }

    private var mediaPickerSheet: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 24) {
                // Document button
                mediaSheetButton(iconName: "doc.fill", label: "Document", color: Color.purple)

                // Camera button
                Button {
                    uiState.showCamera = true
                } label: {
                    mediaSheetButtonView(iconName: "camera.fill", label: "Camera", color: Color.red.opacity(0.8))
                }

                // Image Gallery button
                PhotosPicker(
                    selection: $mediaState.selectedImages,
                    maxSelectionCount: 10,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    mediaSheetButtonView(iconName: "photo.fill", label: "Images", color: Color.cyan)
                }
                .onChange(of: mediaState.selectedImages) { _, newItems in
                    Task {
                        for item in newItems {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                await sendImage(image)
                            }
                        }
                        mediaState.selectedImages.removeAll()
                        uiState.isMediaSheetVisible = false
                    }
                }

                // Video Gallery button
                PhotosPicker(
                    selection: $mediaState.selectedVideos,
                    maxSelectionCount: 2,
                    matching: .videos,
                    photoLibrary: .shared()
                ) {
                    mediaSheetButtonView(iconName: "video.fill", label: "Videos", color: Color.teal)
                }
                .onChange(of: mediaState.selectedVideos) { _, newItems in
                    Task {
                        for item in newItems {
                            if let data = try? await item.loadTransferable(type: Data.self) {
                                await sendVideo(data)
                            }
                        }
                        mediaState.selectedVideos.removeAll()
                        uiState.isMediaSheetVisible = false
                    }
                }

                // Additional buttons
                mediaSheetButton(iconName: "music.note", label: "Audio", color: Color.orange)
                mediaSheetButton(iconName: "location.fill", label: "Location", color: Color.green)
                mediaSheetButton(iconName: "person.fill", label: "Contact", color: Color.indigo)
                mediaSheetButton(iconName: "chart.bar.fill", label: "Poll", color: Color.pink)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.white)
    }

    // Helper function to create consistent media sheet buttons
    private func mediaSheetButton(iconName: String, label: String, color: Color) -> some View {
        Button {
            uiState.isMediaSheetVisible = false
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
}

// MARK: - Supporting Structs
extension FireChatDetailView {
    struct UIState {
        var isMediaSheetVisible: Bool = false
        var isProfileDetailPresented: Bool = false
        var isProfileImagePresented: Bool = false
        var isTyping: Bool = false
        var onlineStatus: Bool? = nil
        var showCamera: Bool = false
        var showPreview: Bool = false
    }

    struct ChatState {
        var chatId: String? = nil
        var chatExists: Bool? = nil
        var lastMessage: FireMessageModel? = nil
        var messageText: String = ""
    }

    struct MediaState {
        var capturedImage: UIImage? = nil
        var selectedImages: [PhotosPickerItem] = []
        var selectedVideos: [PhotosPickerItem] = []
        var selectedMedia: MPMediaItem? = nil
    }
}

#Preview {
    // Add preview code here if needed
}
