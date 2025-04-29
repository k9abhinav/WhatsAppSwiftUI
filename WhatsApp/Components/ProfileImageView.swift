
import SwiftUI

struct ProfileImageView: View {
    let size: CGFloat
    @State private var image: UIImage?
    @Binding var imageData: Data?

    var body: some View {
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
        .onChange(of: imageData){
          _,_ in loadImage()
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        if let data = imageData, !data.isEmpty {
            self.image = UIImage(data: data)
        } else {
            self.image = nil
        }
    }
}

struct ProfileAsyncImageView:View{
    let size: CGFloat
    @State var imageUrlString: String?
    var body: some View{
        Group {
            if let imageUrlString = imageUrlString, let imageUrl = URL(string: imageUrlString),!imageUrlString.hasSuffix(".svg") {
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
