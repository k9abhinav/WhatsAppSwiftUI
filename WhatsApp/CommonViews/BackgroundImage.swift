
import SwiftUI

struct BackgroundImage: View {
    var body: some View {
        Image("bgChats")
            .resizable()
            .opacity(0.3)
            .ignoresSafeArea()
    }
}

#Preview {
    BackgroundImage()
}
