//
//  FireUpdatesRowView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 15/04/25.
//

import SwiftUI

struct FireUpdateRowView: View {
    @Environment(FireUserViewModel.self) private var userViewModel
    let update: FireUpdateModel
    var user: FireUserModel {
        userViewModel.allUsers.first { $0.id == update.userId } ?? FireUserModel(name: "Unknown")
    }
        var body: some View {
            HStack {
                userProfilePictureView
                VStack(alignment: .leading) {
                    Text(user.name)

                    HStack {
                        Image(systemName: iconForMediaType(update.mediaType))
                            .foregroundColor(.primary)
                            .frame(width: 15, height: 15)
                            .background(Circle().fill(Color(.systemGray6)))
                        Text(update.content)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    private var userProfilePictureView: some View {
        Group {
            if let imageUrlString = user.imageUrl, let imageUrl = URL(string: imageUrlString) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 40,height: 40)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40,height: 40)
                            .clipShape(Circle())

                    case .failure:
                        defaultProfileImage
                    @unknown default:
                        EmptyView()
                            .frame(width: 40,height: 40)
                    }
                }

            }
            else{
                defaultProfileImage
            }
        }
    }
    private var defaultProfileImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFill()
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .foregroundColor(.gray)
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

#Preview {

}
