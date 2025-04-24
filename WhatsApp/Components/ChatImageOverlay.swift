import SwiftUI

struct ChatImageOverlay: View {
    let imageData: Data?
    let onDismiss: () -> Void
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Spacer()
                chatImage
                Spacer()
            }
        }
        .zIndex(10)
        .onTapGesture { onDismiss() }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: imageData)
        .onAppear { loadImage() }
    }

    private var chatImage: some View {
        Group {
            if let uiImage = image {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 10)
                    .padding()
            } else {
                defaultImage
            }
        }
    }

    private var defaultImage: some View {
        Image(systemName: "photo.badge.exclamationmark.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 150, height: 150)
            .foregroundColor(.gray)
    }

    private func loadImage() {
        if let imageData = imageData {
            image = UIImage(data: imageData)
        }
    }
}
