import SwiftUI

struct ProfilePicOverlay: View {
    let user: FireUserModel
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Background with fade effect
            Color.black
                .ignoresSafeArea()
                // Tap anywhere to dismiss

            VStack {
                // Close button at top left


                Spacer()

                // Profile Image
                if let imageUrlString = user.imageUrl, let imageUrl = URL(string: imageUrlString) {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: 400) // Adjust height as needed
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(radius: 10)
                                .padding()
                        case .failure:
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .foregroundColor(.gray)
                }

                // User Name Display
                Text(user.name)
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
        .animation(.easeInOut(duration: 0.3), value: user.imageUrl) // Smooth appearance
    }
}
