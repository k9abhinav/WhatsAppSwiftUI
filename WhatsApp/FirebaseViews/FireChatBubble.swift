import SwiftUI
import AVFoundation
import AVKit
// First, update your FireChatBubble to handle voice messages
struct FireChatBubble: View {
    let message: FireMessageModel
    let currentUserId: String
    @State private var showContextMenu = false
    @State private var imageLoadError = false

    // Audio player states
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var playbackProgress: Double = 0
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
        .onDisappear {
            stopAudio()
        }
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
                        Text(message.content)
                            .italic()
                    } else {
                        Text(message.content)
                    }
                }
                .padding(12)
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
                    .foregroundColor(isFromCurrentUser ? .white : .blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        Rectangle()
                            .fill(isFromCurrentUser ? Color.white.opacity(0.3) : Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .cornerRadius(2)

                        // Progress
                        Rectangle()
                            .fill(isFromCurrentUser ? Color.white : Color.blue)
                            .frame(width: geometry.size.width * playbackProgress, height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)

                // Duration
                Text("\(formattedDuration(duration: duration))")
                    .font(.caption)
                    .foregroundColor(isFromCurrentUser ? .white.opacity(0.9) : .gray)
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

    // Audio playback functions
    private func playAudio(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        // Set up audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
            return
        }

        // Download and play the audio
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                print("Failed to download audio: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            DispatchQueue.main.async {
                do {
                    audioPlayer = try AVAudioPlayer(data: data)
                    audioPlayer?.prepareToPlay()
                    audioPlayer?.play()
                    isPlaying = true

                    // Set up timer to update progress
                    startProgressTimer()
                } catch {
                    print("Failed to play audio: \(error)")
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
            } else {
                // Audio finished playing
                if playbackProgress >= 0.99 {
                    stopAudio()
                }
            }
        }
    }

    private func formattedDuration(duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
