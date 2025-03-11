import SwiftUI

struct SplashView: View {
    @Binding var splashViewActive: Bool
    @State private var size = 0.8
    @State private var opacity = 0.4

    var body: some View {
        VStack {
            Image("welcome_image")
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
                .padding()

            Text("WhatsApp Clone")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.customGreen)
        }
        .padding(20)
        .scaleEffect(size)
        .opacity(opacity)
        .onAppear {
            withAnimation( .easeInOut(duration: 1.8) ) {
                size = 0.9
                opacity = 1.0
            }
            Task {
                try? await Task.sleep(nanoseconds: 1_800_000_000) // 1.5 seconds
                withAnimation {
                    splashViewActive = false
                }
            }
        }
    }
}
