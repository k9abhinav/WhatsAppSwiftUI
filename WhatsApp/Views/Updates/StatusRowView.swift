import SwiftUI
import SwiftData
import PhotosUI




struct StatusRowView: View {
    let status: Status

    var body: some View {
        HStack(spacing: 12) {
            if let imageData = status.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Text(String(status.content.prefix(1)).uppercased())
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(status.content)
                    .lineLimit(1)
                    .font(.subheadline)

                Text(status.timeRemaining)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}



//


