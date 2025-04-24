import SwiftUI

struct ProfilePicOverlay: View {
    let imageData: Data?
    @State private var image: UIImage?
    let username : String?
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(.all)
            VStack {
                Spacer()
                profileImage
                Spacer()
                Text(username ?? "Error")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.top, 10)

                Spacer()
            }
        }
        .zIndex(10)
        .onTapGesture { onDismiss() }
        .transition(.opacity) // Smooth fade-in effect
        .animation(.easeInOut(duration: 0.3), value: imageData) // Smooth appearance
    }
    private var profileImage: some View {
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
                DefaultProfileImage(size: 150)
            }
        }
    }

    private func loadImage() {
        if let imageData = imageData {
            image = UIImage(data: imageData)
        }
    }
}
