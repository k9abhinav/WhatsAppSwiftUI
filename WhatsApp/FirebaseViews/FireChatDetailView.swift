import PhotosUI
import SwiftUI

struct FireChatDetailView: View {

    let user: FireUserModel
    @Environment(FireChatViewModel.self) private var chatViewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.presentationMode) private var presentationMode
    @State private var lastMessage : FireMessageModel?
    @FocusState private var isTextFieldFocused: Bool
    @State private var messageText: String = ""
    @State private var isProfileDetailPresented: Bool = false
    @State private var isProfileImagePresented: Bool = false
    @State private var isTyping: Bool = false
    @State private var onlineStatus: Bool = false

    // -------------------------------------- MARK: VIEW BODY ------------------------------------------------------------

    var body: some View {

        ZStack {
            VStack {
                ZStack {
                    backGroundImage
                    mainScrollChatsView
                }
                inputMessageTabBar
                    .background(Color.white)
                    .ignoresSafeArea()
            }
            .modifier(KeyBoardViewModifier())
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

            }
           .onDisappear {

                DispatchQueue.main.async {
                    UITabBar.appearance().isHidden = false
                }
            }

            if isProfileImagePresented {
                ProfilePicOverlay(user: user) {
                    withAnimation(.easeInOut(duration: 0.3)) { isProfileImagePresented = false }
                }
                .transition(.opacity)
            }
        }


    }

    // ----------------------------------- MARK: HELPER FUNCTIONS---------------------------------------------------------

    private func sendMessage() async {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        dismissKeyboard()
        await chatViewModel.sendMessage(
                                    chatId: chatId,
                                    senderId: authViewModel.currentLoggedInUser?.id ?? "",
                                    receiverId: user.id,
                                    content: messageText,
                                    messageType: .text
                                )
        messageText = ""

        isTyping = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isTyping = false
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    //  -----------------------------------------MARK: COMPONENTS -----------------------------------------------------------

    private var backGroundImage: some View {
        Image("bgChats")
            .resizable()
            .scaleEffect(1.4)
            .opacity(0.5)
    }

    private var backButton: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() })
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
                Text(user.onlineStatus ?? false ? "Online" : "Offline").font(.caption).foregroundColor(.gray)
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

    private var mainScrollChatsView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(spacing: 10, pinnedViews: []) {
                    ForEach( chatViewModel.messages , id: \.id) { message in
                        FireChatBubble(message: message , currentUserId: authViewModel.currentLoggedInUser?.id ?? "Error" )
                            .id(message.id)
                    }

                    if isTyping {
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
                if let lastMessage = lastMessage {
                    scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
            .onChange(of: chatViewModel.messages.count ) { _, _ in
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
    }

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
