import SwiftUI

struct FireChatBubble: View {
    let message: FireMessageModel
    let currentUserId: String
    @State private var showContextMenu = false
    @State private var imageLoadError = false

    var onReply: () -> Void = {}
    var onForward: () -> Void = {}
    var onDelete: () -> Void = {}

    private var isFromCurrentUser: Bool {
        message.senderUserId == currentUserId
    }

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                displayImageandContent
                    .background(
                        isFromCurrentUser
                        ? (message.messageType == .image ? Color.gray.opacity(0.2) : Color.customGreen)
                            : Color.gray.opacity(0.2)
                    )
                    .foregroundColor(isFromCurrentUser ? .white : .black)
                    .cornerRadius(16)
                    .font(.body)
                    .contextMenu { contextMenuItems }
                    .onLongPressGesture { feedback() ; showContextMenu = true }
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
            if message.messageType == .image, let _ = message.imageUrl {
                Button("Save Image") {
                    if let imageUrl = message.imageUrl, let url = URL(string: imageUrl) {
                        saveImage(from: url)
                    }
                }
            }
            if isFromCurrentUser {
                Button("Delete", role: .destructive) { onDelete() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    private var displayImageandContent: some View {
        Group {
            if message.messageType == .image, let imageUrl = message.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 300, height: 300)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 300, height: 300)
                            .cornerRadius(10)
                            .padding(10)
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                            .frame(width: 300, height: 300)
                    @unknown default:
                        EmptyView()
                            .frame(width: 300, height: 300)
                    }
                }
                .cornerRadius(10)
            } else {
                //
            }
            if message.messageType == .text {
                Text(message.content)
                    .padding(12)
            }
           
        }
    }
    private var contextMenuItems : some View {
        Group{
            Button(action: onReply) {
                Label("Reply", systemImage: "arrowshape.turn.up.left")
            }

            Button(action: onForward) {
                Label("Forward", systemImage: "arrowshape.turn.up.forward")
            }

            if message.messageType == .image, let imageUrl = message.imageUrl, let url = URL(string: imageUrl) {
                Button(action: {
                    saveImage(from: url)
                }) {
                    Label("Save Image", systemImage: "square.and.arrow.down")
                }
            }

            if isFromCurrentUser {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func feedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func saveImage(from url: URL) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                }
            }
        }
        task.resume()
    }
}
//struct FireChatBubble: View {
//    let message: FireMessageModel
//    let currentUserId: String
//    @State private var showContextMenu = false
//
//    // Define actions for the context menu options
//    var onReply: () -> Void = {}
//    var onForward: () -> Void = {}
//    var onDelete: () -> Void = {}
//
//    private var isFromCurrentUser: Bool {
//        message.senderUserId == currentUserId
//    }
//
//    var body: some View {
//        HStack(alignment: .bottom) {
//            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
//                Text(message.content)
//                    .padding(12)
//                    .background(isFromCurrentUser ? Color.green : Color.gray.opacity(0.2))
//                    .foregroundColor(isFromCurrentUser ? .white : .black)
//                    .cornerRadius(16)
//                    .font(.body)
//                    .contextMenu {
//                        Button(action: onReply) {
//                            Label("Reply", systemImage: "arrowshape.turn.up.left")
//                        }
//
//                        Button(action: onForward) {
//                            Label("Forward", systemImage: "arrowshape.turn.up.forward")
//                        }
//
//                        if isFromCurrentUser {
//                            Button(role: .destructive, action: onDelete) {
//                                Label("Delete", systemImage: "trash")
//                            }
//                        }
//                    }
//                    // Alternative long press gesture if you want a custom menu
//                    .onLongPressGesture {
//                        feedback()
//                        showContextMenu = true
//                    }
//
//                Text(timeString(from: message.timestamp))
//                    .font(.caption2)
//                    .foregroundColor(.gray)
//                    .padding(isFromCurrentUser ? .trailing : .leading, 4)
//            }
//            .frame(maxWidth: UIScreen.main.bounds.width * 0.95, alignment: isFromCurrentUser ? .trailing : .leading)
//        }
//        .confirmationDialog("Message Options", isPresented: $showContextMenu, titleVisibility: .visible) {
//            Button("Reply") { onReply() }
//            Button("Forward") { onForward() }
//            if isFromCurrentUser {
//                Button("Delete", role: .destructive) { onDelete() }
//            }
//            Button("Cancel", role: .cancel) {}
//        }
//    }
//
//    private func timeString(from date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.timeStyle = .short
//        return formatter.string(from: date)
//    }
//
//    // Add haptic feedback for the long press
//    private func feedback() {
//        let generator = UIImpactFeedbackGenerator(style: .medium)
//        generator.impactOccurred()
//    }
//}
