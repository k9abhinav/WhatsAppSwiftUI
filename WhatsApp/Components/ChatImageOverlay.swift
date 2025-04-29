import SwiftUI

struct ChatImageOverlay: View {
    let imageData: Data?
    let onDismiss: () -> Void

    @State private var image: UIImage?
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var isDragging = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Material.ultraThin)
                .background(Color.black.opacity(0.4 - Double(min(offset.height / 1000, 0.4))))
                .ignoresSafeArea()

            if let uiImage = image {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 10)
                    .padding()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(dragGesture())
                    .gesture(magnificationGesture())
                    .animation(.spring(), value: offset)
                    .animation(.spring(), value: scale)
            } else {
                defaultImage
            }
        }
        .zIndex(11)
        .transition(.opacity)
        .onAppear { loadImage() }
        .onTapGesture {
            if scale == 1.0 { onDismiss() }
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

    private func dragGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                if scale == 1.0 {  // Only allow dragging to dismiss if not zoomed
                    offset = value.translation
                    isDragging = true
                }
            }
            .onEnded { value in
                if scale == 1.0 && offset.height > 100 {
                    onDismiss()
                } else {
                    offset = .zero
                    isDragging = false
                }
            }
    }

    private func magnificationGesture() -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = max(1.0, value) // Prevent shrinking below original size
            }
            .onEnded { value in
                if scale < 1.0 {
                    scale = 1.0
                }
            }
    }
}
