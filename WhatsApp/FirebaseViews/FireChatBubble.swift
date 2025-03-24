import SwiftUI

struct FireChatBubble: View {
    let message: FireMessageModel
    let currentUserId: String 
    private var isFromCurrentUser: Bool {
        message.senderUserId == currentUserId
    }

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                Text(message.content)
                    .padding(12)
                    .background(isFromCurrentUser ? Color.green : Color.gray.opacity(0.2))
                    .foregroundColor(isFromCurrentUser ? .white : .black)
                    .cornerRadius(16)
                    .font(.body)

                Text(timeString(from: message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(isFromCurrentUser ? .trailing : .leading, 4)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.95, alignment: isFromCurrentUser ? .trailing : .leading)
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    FireChatBubble(
        message: FireMessageModel(id: "1", content: "Hello!", senderUserId: "123", receiverUserId: "456", timestamp: Date()),
        currentUserId: "123"
    )
}
