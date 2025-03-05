
import SwiftUI
import SwiftData

struct ChatDetailView: View {

    let user: User
    @Environment(ChatsViewModel.self) private var viewModel: ChatsViewModel
    @Environment(\.modelContext) private var context : ModelContext
    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var isTextFieldFocused: Bool
    @State private var scrollViewProxy: ScrollViewProxy?
    @State private var messageText: String = ""
    @State private var isKeyboardShowing: Bool = false
    @State private var isProfilePicPresented: Bool = false
    @State private var isTyping: Bool = false

    // -------------------------------------- MARK: VIEW BODY ------------------------------------------------------------

    var body: some View {
        VStack {
            VStack{
                ZStack{
                    backGroundImage
                    mainScrollChatsView
                }
                inputMessageTabBar
            }
        }
        .modifier(KeyBoardViewModifier())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) { backButton ; topLeftNavItems }
            ToolbarItem(placement: .topBarTrailing) { topRightNavItems }
        }
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

        if let scrollProxy = scrollViewProxy {
            scrollToBottom(scrollProxy, chats: user.chats)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            isTyping = false
            if let scrollProxy = scrollViewProxy {
                scrollToBottom(scrollProxy, chats: user.chats)
            }
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    private func scrollToBottom(_ scrollProxy: ScrollViewProxy, chats: [Chat]) {
        guard let lastMessage = chats.last else { return }

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
                LazyVStack(spacing: 10) {
                    ForEach(user.chats ,id: \.id) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }
                    if isTyping {
                        HStack {
                            ChatTypingIndicator()
                            Spacer()
                        }
                        .padding(.leading, 10)
                        .transition(.opacity)
                        .id("TypingIndicator")
                    }

                }
            }
            .padding(.bottom,10)
            .scrollIndicators(.hidden)
            .onAppear {
                scrollViewProxy = scrollProxy
                scrollToBottom(scrollProxy, chats: user.chats)
            }
            .onChange(of: user.chats.count) { _, _ in
                      if let scrollProxy = scrollViewProxy {
                          scrollToBottom(scrollProxy, chats: user.chats)
                      }
                  }
            .onChange(of: isTyping) { _, _ in
                       if let scrollProxy = scrollViewProxy {
                           scrollToBottom(scrollProxy, chats: user.chats)
                       }
                   }

        }
    }

    private var inputMessageTabBar: some View {
        HStack(spacing: 12) {
            Button(action: { print("Plus button tapped") }) {
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
        .padding(.top, 1)
        .padding(.bottom,5)
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

extension View {
    func keyboardObserving() -> some View {
        modifier(KeyBoardViewModifier())
    }
}

