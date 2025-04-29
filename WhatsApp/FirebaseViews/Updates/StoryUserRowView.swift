//
//  StoryUserRowView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 17/04/25.
//
import SwiftUI

struct StoryUserRowView: View {
    let user: FireUserModel
    let updates: [FireUpdateModel]
    @State private var showingStoryViewer = false
    @State private var userImageData:Data?
    @State private var userImageURLString:String?

    var body: some View {
        Button(action: {
            showingStoryViewer = true
        }) {
            HStack(spacing: 12) {
                // User profile picture with border showing "has updates"
                ZStack {
                    Circle()
                        .stroke(Color.green, lineWidth: 2)
                        .frame(width: 58, height: 58)

                    Group{
                        if let imageData = userImageData, !imageData.isEmpty {
                            ProfileImageView(size: 50, imageData: $userImageData)
                        } else {
                            ProfileAsyncImageView(size: 50, imageUrlString: userImageURLString)
                        }
                    }.frame(width: 50, height: 50)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(.headline)

                    Text(latestUpdateTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Latest update type icon
                if let latestUpdate = updates.sorted(by: { $0.createdAt > $1.createdAt }).first {
                    Image(systemName: iconForMediaType(latestUpdate.mediaType))
                        .foregroundColor(.green)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showingStoryViewer) {
            UpdatesStoryViewerView(updates: updates, startIndex: 0)
        }
        .task{
            guard let url = URL(string: user.imageUrl ?? "") else {
                print("No URL provided for image")
                return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                DispatchQueue.main.async {
                    userImageData = data
                }

            } catch {
                print("Failed to load image data: \(error.localizedDescription)")
            }
        }
        .onAppear{
            if let imageUrl = user.imageUrl, let url = URL(string: imageUrl) {
                userImageURLString = url.absoluteString
            }
        }
    }

    private var latestUpdateTime: String {
        if let latestUpdate = updates.sorted(by: { $0.createdAt > $1.createdAt }).first {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return formatter.localizedString(for: latestUpdate.createdAt, relativeTo: Date())
        }
        return ""
    }

    private func iconForMediaType(_ mediaType: FireUpdateModel.MediaType) -> String {
        switch mediaType {
        case .text:
            return "text.bubble.fill"
        case .image:
            return "photo.fill"
        case .video:
            return "video.fill"
        }
    }
}
