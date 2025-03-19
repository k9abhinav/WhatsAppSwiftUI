import SwiftUI

struct ProfilePicOverlay: View {
//    let user: User
    let user: FireUserModel
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.secondary.opacity(0.85) // Background dim effect
                .edgesIgnoringSafeArea(.all)
            ZStack {
                Text(user.name)
                    .background(Color.black.opacity(0.8))
                    .frame(width:300 , alignment: .leading)
                    .font(.title)
                    .frame(maxWidth: .greatestFiniteMagnitude ,maxHeight: .greatestFiniteMagnitude, alignment: .topLeading)
                    .foregroundStyle(.white)
                    .zIndex(1)
                VStack{

                        //                    if let imageData = user.imageData,
                        if let imageUrlString = user.imageUrl, let imageUrl = URL(string: imageUrlString) {
                            AsyncImage(url: imageUrl) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 300, height: 300) // Adjust size as needed
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .shadow(radius: 10)
                                case .failure:
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.gray)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                        else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)

                        }


                }
//                .background(Color.customGreen)

            }
            .frame(width: 300,height: 300)
          
        }
        .frame(maxWidth: .infinity - 300, alignment: .center )
        .onTapGesture { onDismiss() }
        .transition(.opacity) // Smooth fade-in effect
    }
}
#Preview {

}
