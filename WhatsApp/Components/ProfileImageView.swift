
import SwiftUI

struct ProfileImageView: View {
    let size: CGFloat
    @State var image:UIImage?
    @Binding var imageData: Data?
    var body: some View {
        profileImage
            .task{  loadImage() }
    }
    private var profileImage: some View {
        Group {
            if let uiImage = image {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                DefaultProfileImage(size: size)
            }
        }
    }

    private func loadImage() {
        if let imageData = imageData {
            image = UIImage(data: imageData)
        }
    }
}

struct ProfileAsyncImageView:View{
    let size: CGFloat
    @State var imageUrlString: String?
    var body: some View{
        Group {
            if let imageUrlString = imageUrlString, let imageUrl = URL(string: imageUrlString) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        DefaultProfileImage(size: size)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size,height: size)
                            .clipShape(Circle())

                    case .failure:
                        DefaultProfileImage(size: size)
                    @unknown default:
                        EmptyView()
                            .frame(width: size,height: size)
                    }
                }

            }
            else{
                DefaultProfileImage(size:size)
            }
        }
    }
}
#Preview {
    //    ProfileImageView(size: 32,)
}
