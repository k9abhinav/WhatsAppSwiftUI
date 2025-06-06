import SwiftUI
import AVFoundation
import AVKit

struct UpdatesStoryViewerView: View {
    let updates: [FireUpdateModel]
    let startIndex: Int

    @State private var currentIndex: Int
    @State private var progressValue: Double = 0
    @State private var timer: Timer?
    @State private var remainingTime: Double = 5.0
    @State private var isPaused: Bool = false

    @Environment(\.dismiss) private var dismiss
    @Environment(FireUserViewModel.self) private var userViewModel

    init(updates: [FireUpdateModel], startIndex: Int) {
        self.updates = updates
        self.startIndex = startIndex
        _currentIndex = State(initialValue: startIndex)
    }

    var currentUpdate: FireUpdateModel? {
        guard !updates.isEmpty, currentIndex < updates.count else { return nil }
        return updates[currentIndex]
    }

    var currentUser: FireUserModel? {
        guard let update = currentUpdate else { return nil }
        return userViewModel.allUsers.first { $0.id == update.userId }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                if let update = currentUpdate {
                    VStack {
                        // Progress Bars
                        HStack(spacing: 4) {
                            ForEach(0..<updates.count, id: \.self) { index in
                                ProgressBar(
                                    value: index == currentIndex ? progressValue : (index < currentIndex ? 1.0 : 0.0)
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)

                        // User Info and Close Button
                        HStack {
                            if let user = currentUser {
                                HStack {
                                    if let imageUrlString = user.imageUrl, let imageUrl = URL(string: imageUrlString) {
                                        AsyncImage(url: imageUrl) { phase in
                                            switch phase {
                                            case .empty:
                                                DefaultProfileImage(size: 36)
                                            case .success(let image):
                                                image.resizable()
                                                    .scaledToFill()
                                                    .frame(width: 36, height: 36)
                                                    .clipShape(Circle())
                                            case .failure:
                                                DefaultProfileImage(size: 36)
                                            @unknown default:
                                                EmptyView()
                                                    .frame(width: 36, height: 36)
                                            }
                                        }
                                    } else {
                                        DefaultProfileImage(size: 36)
                                    }

                                    VStack(alignment: .leading) {
                                        Text(user.name)
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                        Text(update.timeRemaining)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }

                            Spacer()

                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                        }
                        .padding(.horizontal)

                        Spacer()

                        // Content
                        ZStack {
                            switch update.mediaType {
                            case .text:
                                Text(update.content)
                                    .font(.largeTitle.bold())
                                    .multilineTextAlignment(.center)
                                    .padding()
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue.opacity(0.7))
                                    .cornerRadius(12)
                                    .padding()

                            case .image:
                                if let urlString = update.mediaUrl, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView().tint(.white)
                                        case .success(let image):
                                            image.resizable()
                                                .scaledToFit()
                                                .frame(maxHeight: geometry.size.height * 0.7)
                                                .cornerRadius(12)
                                                .overlay(
                                                    Text(update.content)
                                                        .multilineTextAlignment(.center)
                                                        .padding()
                                                        .background(.ultraThinMaterial)
                                                        .cornerRadius(8)
                                                        .padding(),
                                                    alignment: .bottom
                                                )
                                        case .failure:
                                            Image(systemName: "photo.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 100, height: 100)
                                                .foregroundColor(.red)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .onAppear { resetTimer() }
                                }

                            case .video:
                                if let urlString = update.mediaUrl, let url = URL(string: urlString) {
                                    VideoPlayer(player: AVPlayer(url: url))
                                        .cornerRadius(12)
                                        .overlay(
                                            Text(update.content)
                                                .multilineTextAlignment(.center)
                                                .padding()
                                                .background(.ultraThinMaterial)
                                                .cornerRadius(8)
                                                .padding(),
                                            alignment: .bottom
                                        )
                                        .onAppear {
                                            resetTimer(seconds: 15.0)
                                        }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        LongPressGesture(minimumDuration: 0.2)
                            .onChanged { _ in
                                pause()
                            }
                            .onEnded { _ in
                                resume()
                            }
                        .simultaneously(
                            with: DragGesture(minimumDistance: 10)
                                .onEnded { value in
                                    let locationX = value.location.x
                                    let width = geometry.size.width

                                    if locationX < width * 0.3 {
                                        goToPrevious()
                                    } else if locationX > width * 0.7 {
                                        goToNext()
                                    }
                                }
                        )
                    )
                }
            }
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
        }
    }

    // MARK: Timer Logic

    private func startTimer() {
        resetTimer()
    }

    private func resetTimer(seconds: Double = 5.0) {
        stopTimer()
        remainingTime = seconds
        progressValue = 0.0

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard !isPaused else { return }

            if remainingTime > 0.1 {
                remainingTime -= 0.1
                progressValue = 1.0 - (remainingTime / seconds)
            } else {
                goToNext()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func pause() {
        isPaused = true
    }

    private func resume() {
        isPaused = false
    }

    // MARK: Navigation

    private func goToNext() {
        if currentIndex < updates.count - 1 {
            currentIndex += 1
            startTimer()
        } else {
            dismiss()
        }
    }

    private func goToPrevious() {
        if currentIndex > 0 {
            currentIndex -= 1
            startTimer()
        }
    }
}
