
import SwiftUI
import SwiftData

struct ChatDetailView: View {

    let user: User
    @Environment(\.modelContext) private var context
    @Environment(\.presentationMode) var presentationMode
    @Environment(ChatsViewModel.self) var chatsViewModel: ChatsViewModel
    @FocusState private var isTextFieldFocused: Bool
    @State private var scrollViewProxy: ScrollViewProxy?
    @State private var messageText = ""
    @State private var isTyping : Bool = false
    
    // -------------------------------------- VIEW BODY ------------------------------------------------------------
    var body: some View {
        VStack {
            ZStack{
                Image("bgChats")                     // Chats BackGround Image
                    .resizable()
                    .scaledToFill()
                    .opacity(0.5)
                mainScrollChatsView
            }
            inputMessageTabBar
        }
        .keyboardObserving()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                backButton
                topLeftNavItems
            }
            ToolbarItem(placement: .topBarTrailing) {
                topRightNavItems
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .onDisappear {
            withAnimation {
                UITabBar.appearance().isHidden = false
            }
        }
    }

    //       -----------------------------------      MARK: HELPER FUNCTIONS--------------------------------- --
    private func sendMessage() {
        chatsViewModel.sendMessage(user: user, messageText: messageText, context: context)
        messageText = ""
    }
    //    -----------------------------------------MARK: COMPONENTS ------------------------------------------------------------
    private var backButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        })
        {
            HStack {
                Image(systemName: "arrow.backward")
            }
        }
    }
    private var topLeftNavItems: some View {
        HStack {
            if let imageData = user.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill") // Fallback image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading) {
                Text(user.name)
                    .font(.headline)
                Text("Online") // You can later update this dynamically
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }

    private var topRightNavItems: some View {
        HStack {
            Button(action: {
                print("Video call tapped")
            }) {
                Image(systemName: "video")
            }

            Button(action: {
                print("Phone call tapped")
            }) {
                Image(systemName: "phone")
            }
        }
    }
    private var inputMessageTabBar: some View {
        HStack(spacing: 12) {
//            Button(action: {
//                print("Plus button tapped")
//            }) {
//                Image(systemName: "plus")
//                    .font(.system(size: 22))
//                    .foregroundColor(.gray)
//            }

            TextField("Message", text: $messageText)
                .focused($isTextFieldFocused)
                .submitLabel(.next)
//                .onSubmit {
//                    sendMessage()
//                }
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)

            Button(action: {
                sendMessage()
            }) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.green)
            }.disabled(messageText.isEmpty)
        }
        .padding(.horizontal)
        .padding(.top, 1)
        .padding(.bottom,6)
    }


    private var mainScrollChatsView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(user.chats ,id: \.id) { message in
                        MessageBubble(message: message)
                            .id(message.id) // Assign an ID for scrolling
                    }
                    if chatsViewModel.isTyping {
                        TypingIndicatorView()
                            .id("typingIndicator")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .padding(.horizontal, 25)

            }
            .scrollIndicators(.hidden)
            .onAppear {
                scrollViewProxy = scrollProxy
                chatsViewModel.scrollToBottom(scrollProxy, chats: user.chats)
            }
            .onChange(of: user.chats) { _,newChats in
                        guard let lastMessage = newChats.last else { return }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
            .onChange(of: chatsViewModel.isTyping) { _,isTyping in
                        if isTyping {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    scrollProxy.scrollTo("typingIndicator", anchor: .bottom)
                                }
                            }
                        }
                    }

        }
    }


}


import Combine
import SwiftUI

struct KeyboardObserving: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    private let publisher = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onReceive(publisher) { notification in
                if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = frame.height
                }
            }
    }
}

extension View {
    func keyboardObserving() -> some View {
        modifier(KeyboardObserving())
    }
}

