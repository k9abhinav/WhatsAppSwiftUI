import SwiftUI

struct FireChatBubble: View {
    let message: FireMessageModel
    let currentUserId: String
    @State private var showContextMenu = false

    // Define actions for the context menu options
    var onReply: () -> Void = {}
    var onForward: () -> Void = {}
    var onDelete: () -> Void = {}

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
                    .contextMenu {
                        Button(action: onReply) {
                            Label("Reply", systemImage: "arrowshape.turn.up.left")
                        }

                        Button(action: onForward) {
                            Label("Forward", systemImage: "arrowshape.turn.up.forward")
                        }

                        if isFromCurrentUser {
                            Button(role: .destructive, action: onDelete) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    // Alternative long press gesture if you want a custom menu
                    .onLongPressGesture {
                        feedback()
                        showContextMenu = true
                    }

                Text(timeString(from: message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(isFromCurrentUser ? .trailing : .leading, 4)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.95, alignment: isFromCurrentUser ? .trailing : .leading)
        }
        .confirmationDialog("Message Options", isPresented: $showContextMenu, titleVisibility: .visible) {
            Button("Reply") { onReply() }
            Button("Forward") { onForward() }
            if isFromCurrentUser {
                Button("Delete", role: .destructive) { onDelete() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // Add haptic feedback for the long press
    private func feedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
