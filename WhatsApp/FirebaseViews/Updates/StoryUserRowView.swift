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
                    
                    userProfilePictureView
                        .frame(width: 50, height: 50)
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
    }
    
    private var latestUpdateTime: String {
        if let latestUpdate = updates.sorted(by: { $0.createdAt > $1.createdAt }).first {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return formatter.localizedString(for: latestUpdate.createdAt, relativeTo: Date())
        }
        return ""
    }
    
    private var userProfilePictureView: some View {
        Group {
            if let imageUrlString = user.imageUrl, let imageUrl = URL(string: imageUrlString) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        DefaultProfileImage(size: 50)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    case .failure:
                        DefaultProfileImage(size: 50)
                    @unknown default:
                        EmptyView()
                            .frame(width: 50, height: 50)
                    }
                }
            } else {
                DefaultProfileImage(size: 50)
            }
        }
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
