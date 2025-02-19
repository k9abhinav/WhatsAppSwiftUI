//
//  ChatDetailView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 14/02/25.
//

import SwiftUI

struct Message: Identifiable {
    let id = UUID()
    let content: String
    let isFromCurrentUser: Bool
    let timestamp: Date
}

struct ChatDetailView: View {
    let contact: Contact
    @State private var messageText = ""
    @State private var messages: [Message] = [
        Message(content: "Hey there!", isFromCurrentUser: false, timestamp: Date()),
        Message(content: "Hi! How are you?", isFromCurrentUser: true, timestamp: Date())
    ]

    var body: some View {
        VStack {
            ZStack{
                Image("bgChats")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.5)
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding()
                    .padding(.horizontal, 15)
                }.scrollIndicators(.hidden)
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
    }

    private func sendMessage() {
        guard !messageText.isEmpty else { return }

        let newMessage = Message(content: messageText, isFromCurrentUser: true, timestamp: Date())
        messages.append(newMessage)

        let replyText = messageText // Capture the text to reply with
        messageText = ""

        // Simulate a reply after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.75) {
            let replyMessage = Message(content: replyText, isFromCurrentUser: false, timestamp: Date())
            messages.append(replyMessage)
        }
    }

}

struct MessageBubble: View {
    let message: Message

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
//#Preview {
//    ChatDetailView(contact: .init(name: "John Doe", phone: "+1234567890", imageData:  nil))
//}
