import SwiftUI

struct ProfilePicOverlay: View {
//    let user: User
    let user: FireUserModel
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.secondary.opacity(0.85) // Background dim effect
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 20){
                Text(user.name)
                    .font(.headline)
                Group{
//                    if let imageData = user.imageData,
                    if let imageData = user.imageUrl?.data(using: .utf8)  ,
                        let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
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
            }
        }
        .frame(maxWidth: .infinity - 300, alignment: .center )
        .onTapGesture { onDismiss() }
        .transition(.opacity) // Smooth fade-in effect
    }
}
