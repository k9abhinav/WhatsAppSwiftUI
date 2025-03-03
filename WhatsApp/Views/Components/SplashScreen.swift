
import SwiftUI

struct SplashScreen: View {

    @Binding var splashViewActive: Bool
    @State private var size = 0.8
    @State private var opacity = 0.4

    var body: some View {
        VStack {
            VStack {
                Image("whatsapp")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding()
                Text("WhatsApp")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            .scaleEffect(size)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5)) {
                    size = 0.9
                    opacity = 1.0
                }
                //                main thread
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        splashViewActive = false
                    }
                }
            }
        }
    }
}








//  The onAppear view modifier is called just after a view appears on screen. It's a great place to perform setup tasks, load data, start animations, or anything else you want to happen when the view becomes visible.
//                DispatchQueue is used for managing the execution of code asynchronously (not immediately). This is essential for tasks that might take some time (like network requests, file operations, or delays) so that they don't block the main thread (the thread that updates the UI).
//                DispatchQueue.main.asyncAfter: This specific method schedules a block of code to be executed on the main thread after a specified delay. It's used here to create the 2.5-second delay before transitioning to the MainTabView
