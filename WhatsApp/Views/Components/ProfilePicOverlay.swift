import SwiftUI

struct ProfilePicOverlay: View {
    let user: User
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85) // Background dim effect
                .edgesIgnoringSafeArea(.all)
                .onTapGesture { onDismiss() }

            if let imageData = user.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300) // Adjust size as needed
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 10)
            } else {
                Image(systemName: "person.crop.circle.fill") // Default placeholder
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }
        }
        .transition(.opacity) // Smooth fade-in effect
    }
}
