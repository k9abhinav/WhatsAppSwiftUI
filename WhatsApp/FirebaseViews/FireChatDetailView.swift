import PhotosUI
import SwiftUI

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
    @State private var chatId: String?
    @State private var messageText: String = ""
    @State private var isProfileDetailPresented: Bool = false
    @State private var isProfileImagePresented: Bool = false
    @State private var isTyping: Bool = false
    @State private var onlineStatus: Bool?
    @State private var chatExists: Bool? = nil
    @Binding var navigationPath: NavigationPath
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var selectedVideos: [PhotosPickerItem] = []

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
                onChangeOfOnlineStatusFunction(newValue: newValue )
            }
            .onDisappear {
                onDisappearFunctions()
            }
            //            profilePicOverlayZStack
        }
    }

    // ----------------------------------- MARK: HELPER FUNCTIONS---------------------------------------------------------
    private func onChangeOfOnlineStatusFunction(newValue: Bool?){
        onlineStatus = newValue
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
        if isTyping {
            isTyping = false
        }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    private func sendImage(_ image: UIImage) async {
        guard let currentUserId = authViewModel.currentLoggedInUser?.id else { return }

        Task {
            var chatId:String?
            if chatExists == false {
                await chatViewModel.createNewChat(for: [authViewModel.currentLoggedInUser?.id ?? "", user.id])
                chatId = await chatViewModel.loadChatId(for: [authViewModel.currentLoggedInUser?.id ?? "", user.id])
                print("THE CHAT ID ---- > \(chatId ?? "NO CHATID HERE ---❌---")")
            }
            await messageViewModel.sendImageMessage(
                chatId: chatId ?? "",
                currentUserId: currentUserId,
                otherUserId: user.id,
                imageData: image
            )
        }
    }
    private func sendVideo(_ videoData: Data) async {
        guard let currentUserId = authViewModel.currentLoggedInUser?.id else { return }

        Task {
            var chatId: String?
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
        Group{
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
            Menu {
                // Image Picker Option
                PhotosPicker(
                    selection: $selectedImages,
                    maxSelectionCount: 2,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Images", systemImage: "photo.on.rectangle")
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


                // Video Picker Option
                PhotosPicker(
                    selection: $selectedVideos,
                    maxSelectionCount: 2,
                    matching: .videos,
                    photoLibrary: .shared()
                ) {
                    Label("Videos", systemImage: "film")
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

                // Audio Picker Option
                Button(action: {
                    // Your audio selection code here
                }) {
                    Label("Audio", systemImage: "waveform")
                }

                // Contact Picker Option
                Button(action: {
                    // Your contact selection code here
                }) {
                    Label("Contact", systemImage: "person.crop.circle")
                }

                // Location Option
                Button(action: {
                    // Your location sharing code here
                }) {
                    Label("Location", systemImage: "location.fill")
                }
            } label: {
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
            if(!isTextFieldFocused){
                VoiceRecordButton { audioURL, duration in
                    Task {
                        await messageViewModel.sendVoiceMessage(
                            chatId: chatId ?? "Error: No chatId",
                            currentUserId: authViewModel.currentLoggedInUser?.id ?? "Error: No currentUserId",
                            otherUserId: user.id ,
                            audioFileURL: audioURL,
                            duration: duration
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 5)
        .background(Color.white)
        .ignoresSafeArea()
    }
    private var inputMessageTabView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut) {
                        isMediaSheetVisible.toggle()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22))
                        .foregroundColor(.gray)
                }

                TextField("Message", text: $messageText)
                    .focused($isTextFieldFocused)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)

                Button(action: { Task { await sendMessage() } }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.customGreen)
                }
                .disabled(messageText.isEmpty)

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
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 5)
            .background(Color.white)

            if isMediaSheetVisible {
                mediaPickerSheet
                    .transition(.move(edge: .bottom))
            }
        }
    }
    private var mediaPickerSheet: some View {
        VStack(spacing: 20) {
            HStack(spacing: 30) {
                mediaButton(icon: "photo", title: "Photo") {
                    // Open Photos
                }
                mediaButton(icon: "video", title: "Video") {
                    // Open Videos
                }
                mediaButton(icon: "waveform", title: "Audio") {
                    // Audio action
                }
                mediaButton(icon: "location", title: "Location") {
                    // Location action
                }
            }
            .padding()


        }
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))

    }
    private func mediaButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        VStack {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.title)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
            Text(title).font(.caption)
        }
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
