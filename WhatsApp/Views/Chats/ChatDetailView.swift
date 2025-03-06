import SwiftUI
import SwiftData
import PhotosUI

struct ChatDetailView: View {

    let user: User
    @Environment(ChatsViewModel.self) private var viewModel: ChatsViewModel
    @Environment(\.modelContext) private var context : ModelContext
    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var isTextFieldFocused: Bool
    @State private var messageText: String = ""
    @State private var isProfilePicPresented: Bool = false
    @State private var isTyping: Bool = false

    // -------------------------------------- MARK: VIEW BODY ------------------------------------------------------------

    var body: some View {
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
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) { backButton ; topLeftNavItems }
            ToolbarItem(placement: .topBarTrailing) { topRightNavItems }
        }
        .toolbarBackground(.white, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onDisappear {
            withAnimation(.spring) { UITabBar.appearance().isHidden = false }
        }
    }

    // ----------------------------------- MARK: HELPER FUNCTIONS---------------------------------------------------------

    private func sendMessage() {
        dismissKeyboard()
        viewModel.sendMessage(user: user, messageText: messageText, context: context)
        messageText = ""
        isTyping = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isTyping = false
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func scrollToBottom(_ scrollProxy: ScrollViewProxy) {
        guard let lastMessage = user.chats.last else { return }
        DispatchQueue.main.async {
            withAnimation(.smooth) {
                scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }

    //  -----------------------------------------MARK: COMPONENTS -----------------------------------------------------------

    private var backGroundImage: some View {
        Image("bgChats")
            .resizable()
            .scaledToFill()
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
            VStack(alignment: .leading) {
                Text(user.name).font(.headline)
                Text("Online").font(.caption).foregroundColor(.gray)
            }
        }
        .onTapGesture {
            isProfilePicPresented.toggle()
        }
        .popover(isPresented: $isProfilePicPresented) {
            ProfilePicView(user: user).presentationDetents([.fraction(0.65)])
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
                    ForEach(user.chats, id: \.id) { message in
                        ChatBubble(message: message)
                            .id(message.id)

                    }

                    if isTyping {
                        HStack {
                            ChatTypingIndicator()
                            Spacer()
                        }
                        .padding(.leading, 50)
                        .transition(.opacity)
                        .id("TypingIndicator")
                    }
                }
            }
            .scrollIndicators(.hidden)
            .onAppear {

                if let lastMessage = user.chats.last {
                    scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
            .onChange(of: user.chats.count) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    if let lastMessage = user.chats.last {
                        withTransaction(Transaction(animation: nil)) {
                            scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            .onChange(of: isTextFieldFocused) { _, isFocused in
                if isFocused {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let lastMessage = user.chats.last {
                            scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            .onChange(of: isTyping) { _, newValue in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {

                        if newValue {
                            scrollProxy.scrollTo("TypingIndicator", anchor: .bottom)
                        } else if let lastMessage = user.chats.last {
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
            Button(action: { sendMessage() }) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.green)
            }
            .disabled(messageText.isEmpty)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 5)
    }

    private var profileImage: some View {
        Group {
            if let imageData = user.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .foregroundColor(.gray)
            }
        }
    }

}


//    .onAppear {
//        let storageKey = "lastReadMessage_\(user.id)"
//        lastReadMessageID = UserDefaults.standard.string(forKey: storageKey) ?? ""
//        print("USER ID : -->  \(lastReadMessageID)")
//
//        if lastReadMessageID.isEmpty {
//            scrollProxy.scrollTo(lastReadMessageID, anchor: .bottom)
//        } else if let lastMessage = user.chats.last {
//            scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
//        }
//    }
