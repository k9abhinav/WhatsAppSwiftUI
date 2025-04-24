import SwiftUI
import AVFoundation
import AVKit
// First, update your FireChatBubble to handle voice messages
struct FireChatBubble: View {
    @Environment(FireUserViewModel.self) private var userViewModel
    @Environment(FireChatViewModel.self) private var chatViewModel
    @Environment(FireMessageViewModel.self) private var messageViewModel
    @Environment(UtilityClass.self) private var utilityVM
    let message: FireMessageModel
    let currentUserId: String
    let userId:String
    var user: FireUserModel {
        userViewModel.allUsers.first { $0.id == userId } ?? FireUserModel(name: "Unknown")
    }
    @Binding var chatImageDetailView : Bool
    @Binding var chatId: String?
    @Binding var currentChatImageData: Data?
    @State private var imageURLData: Data?
    @State private var chatExists: Bool = false
    @State private var showContextMenu = false
    @State private var imageLoadError = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var playbackProgress: CGFloat = 0
    @State private var playbackTimer: Timer?

    var onReply: () -> Void = {}
    var onForward: () -> Void = {}
    var onDelete: () -> Void = {}

    private var isFromCurrentUser: Bool {
        message.senderUserId == currentUserId
    }

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                displayMessageContent
                    .background(
                        isFromCurrentUser
                        ? (message.messageType == .image || message.messageType == .voice ? Color.gray.opacity(0.2) : Color.customGreen)
                        : Color.gray.opacity(0.2)
                    )
                    .foregroundColor(isFromCurrentUser ? .white : .black)
                    .cornerRadius(16)
                    .font(.body)
                    .contextMenu { contextMenuItems }
                    .onLongPressGesture { feedback() ; showContextMenu = true }
                HStack{
                    if(!isFromCurrentUser){ messageReadSymbol }
                    Text(utilityVM.timeStringShort(from: message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(isFromCurrentUser ? .trailing : .leading, 4)
                    if(isFromCurrentUser){messageReadSymbol}
                }
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
        .task{
            guard let url = URL(string: user.imageUrl ?? "") else {
                print("No URL provided for image")
                return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                DispatchQueue.main.async {
                    imageURLData = data
                }

            } catch {
                print("Failed to load image data: \(error.localizedDescription)")
            }
        }
        .onAppear{
            if !(message.isSeen ?? false) {

              Task{
                  await messageViewModel.markMessageAsSeen(messageId: message.id, chatId: chatId ??  "Error" )
              }
                }
        }
        .onDisappear {
            stopAudio()
        }
    }
    private var messageReadSymbol: some View {
        Group{
            if(message.isSeen == false ){
                Image("receivedMessage")
                    .resizable()
            } else if (message.isSeen == true){
                Image("seenMessage")
                    .resizable()
            }
            else if (message.isSeen == nil){
                Image("sentMessage")
                    .resizable()
            }
        }
        .frame(width: 8, height: 8)
    }
    // Updated to include voice messages
    private var displayMessageContent: some View {
        VStack {
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
                            .onTapGesture {
                                currentChatImageData = imageURLData
                                chatImageDetailView.toggle()
                            }

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
            } else if message.messageType == .voice, let audioUrl = message.voiceUrl {
                voiceMessageView(audioUrl: audioUrl, duration: message.voiceDuration ?? 0)
            }
            else if message.messageType == .video, let videoUrl = message.videoUrl, let url = URL(string: videoUrl) {
                        VideoPlayer(player: AVPlayer(url: url))
                            .frame(width: 300, height: 300)
                            .cornerRadius(10)
                            .padding(10)
                    }
            else if message.messageType == .text {
                Group {
                    if(message.content == "You deleted this message"){
                        Text(isFromCurrentUser ? "You deleted this message":"This message was deleted")
                            .italic()
                    } else {
                        Text(message.content)
                    }
                }
                .padding(12)
            }
            else{
                ProgressView()
                    .frame(width: 300, height: 300)
            }
        }
    }

    // Voice message player view
    private func voiceMessageView(audioUrl: String, duration: TimeInterval) -> some View {
        HStack(spacing: 12) {
            Button(action: {
                isPlaying ? stopAudio() : playAudio(from: audioUrl)
            }) {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(isFromCurrentUser ? Color.customGreen : Color.blue)
            }

            VStack(alignment: .leading, spacing: 4) {

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {

                        Rectangle()
                            .fill(isFromCurrentUser ? Color.white.opacity(0.3) : Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .cornerRadius(2)


                        Rectangle()
                            .fill(isFromCurrentUser ? Color.customGreen : Color.blue)
                            .frame(width: geometry.size.width * playbackProgress, height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)

                Text("\(formattedDuration(duration: duration))")
                    .font(.caption)
                    .foregroundColor(isFromCurrentUser ? Color.black.opacity(0.5) : .gray)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(width: 220)
    }

    private var contextMenuItems : some View {
        Group {
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

    // Audio playback functions
    private func playAudio(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Audio session error: \(error)")
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                print("Download error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            DispatchQueue.main.async {
                do {
                    audioPlayer = try AVAudioPlayer(data: data)
                    audioPlayer?.prepareToPlay()
                    audioPlayer?.play()
                    isPlaying = true
                    startProgressTimer()
                } catch {
                    print("Playback error: \(error)")
                }
            }
        }.resume()
    }

    private func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        playbackProgress = 0
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    private func startProgressTimer() {
        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let player = audioPlayer, player.isPlaying {
                playbackProgress = player.currentTime / player.duration
            }
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            stopAudio()
        }
    }


    private func formattedDuration(duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
