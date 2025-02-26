//
//  ChatDetailView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 14/02/25.
//

import SwiftUI
import SwiftData

@Model
class ChatMessage {
    var id: UUID
    var content: String
    var isFromCurrentUser: Bool
    var timestamp: Date
    var contactId: String  // to link messages with contacts

    init(content: String, isFromCurrentUser: Bool, contactId: String) {
        self.id = UUID()
        self.content = content
        self.isFromCurrentUser = isFromCurrentUser
        self.timestamp = Date()
        self.contactId = contactId
    }
}


struct Message: Identifiable {
    let id = UUID()
    let content: String
    let isFromCurrentUser: Bool
    let timestamp: Date
}

struct ChatDetailView: View {
    let contact: Contact
    @FocusState private var isTextFieldFocused: Bool
    @State private var messageText = ""

    @State private var isTyping = false

    //    @State private var messages: [Message] = [
    //        Message(content: "Hey there!", isFromCurrentUser: false, timestamp: Date()),
    //        Message(content: "Hi! How are you?", isFromCurrentUser: true, timestamp: Date())
    //    ]
    //    @Query(sort: \Message.timestamp) private var allMessages: [Message]
    @Query private var allMessages: [ChatMessage]

    private var messages: [ChatMessage] {
        allMessages.filter { $0.contactId == contact.phone }
            .sorted { $0.timestamp < $1.timestamp }
    }
    @Environment(\.modelContext) private var context
    @State private var scrollViewProxy: ScrollViewProxy?

    var body: some View {
        VStack {
            ZStack{
                Image("bgChats")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.5)
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id) // Assign an ID for scrolling
                            }
                            if isTyping {
                                   TypingIndicatorView()
                                    .frame(maxWidth:.infinity ,alignment: .leading)
                                       .id("typingIndicator") // Assign an ID for scrolling
                               }
                        }
                        .padding()
                        .padding(.horizontal, 25)
                    }
                    .scrollIndicators(.hidden)
                    .onAppear {
                           // Scroll to last message when view appears
                           scrollToBottom(scrollProxy)
                       }
                       .onChange(of: messages.count) {
                           // Scroll to last message when new messages arrive
                           scrollToBottom(scrollProxy)
                       }
                    // Function to scroll to the bottom

                }
                

            }
            HStack(spacing: 12) {
                Button(action: {
                    print("Plus button tapped")
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 22))
                        .foregroundColor(.gray)
                }

                TextField("Message", text: $messageText)
                    .focused($isTextFieldFocused)
                    .submitLabel(.next)
                    .onSubmit {
                        sendMessage()
                    }
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)

                Button(action: {
                    sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            .padding(.top, 1)
            .padding(.bottom,6)

        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            print("Current messages count: \(messages.count)")
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack {
                    if let imageData = contact.imageData, let uiImage = UIImage(data: imageData) {
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
                        Text(contact.name)
                            .font(.headline)
                        Text("Online") // You can later update this dynamically
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
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
        }
        .toolbar(.hidden, for: .tabBar)
        .onDisappear {
            withAnimation {
                UITabBar.appearance().isHidden = false
            }
        }
        

    }

    private func scrollToBottom(_ scrollProxy: ScrollViewProxy) {
        if let lastMessage = messages.last {
            DispatchQueue.main.async {
                withAnimation {
                    scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }

    private func sendMessage() {
        guard !messageText.isEmpty else { return }

        let newMessage = ChatMessage(
            content: messageText,
            isFromCurrentUser: true,
            contactId: contact.phone
        )
        context.insert(newMessage)
        let sentMessageText = messageText
        messageText = ""

           isTyping = true

        Task {
            try await Task.sleep(nanoseconds: 1_750_000_000) // Sleep for 1.75 seconds

            let replyMessage = ChatMessage(
                content: generateReply(for: sentMessageText),


                isFromCurrentUser: false,
                contactId: contact.phone
            )
            context.insert(replyMessage)
            isTyping = false
            print("Reply sent: \(replyMessage.content)")

            try? context.save()
        }

        try? context.save()
    }

    // Simple function to generate a reply
    private func generateReply(for userMessage: String) -> String {
        let replies = [
            "That's interesting!",
            "I see what you mean.",
            "Tell me more!",
            "Haha, good one!",
            "Let's catch up soon!",
            "😂",
            "👍"
        ]
        return replies.randomElement() ?? "I hear you!"
    }


}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
            }

            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading) {
                Text(message.content)
                    .padding(12)
                    .background(message.isFromCurrentUser ? Color.green : Color.gray.opacity(0.2))
                    .foregroundColor(message.isFromCurrentUser ? .white : .black)
                    .cornerRadius(16)

                Text(timeString(from: message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            if !message.isFromCurrentUser {
                Spacer()
            }
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

let dummyContact = Contact(name: "John Doe", phone: "+1234567890", imageData: nil)

#Preview {
    ChatDetailView(contact: dummyContact)
        .modelContainer(for: ChatMessage.self, inMemory: true)
        
}
