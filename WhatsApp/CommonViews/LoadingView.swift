import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    @State private var shimmer = false
    @Namespace private var animation

      var body: some View {
          ZStack {
              Color(.systemBackground)
                  .ignoresSafeArea()

              VStack(spacing: 40) {

                  ZStack {
                      Circle()
                          .fill(Color.customGreen.opacity(0.3))
                          .frame(width: 150, height: 150)
                          .scaleEffect(isAnimating ? 1.1 : 0.9)
                          .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)

                      Image(systemName: "ellipsis.message.fill")
                          .resizable()
                          .scaledToFit()
                          .frame(width: 80, height: 80)
                          .foregroundColor(.customGreen)
                          .shadow(color: .customGreen.opacity(0.7), radius: 15, x: 0, y: 0)
                          .rotationEffect(.degrees(isAnimating ? 360 : 0))
                          .animation(.linear(duration: 2.5).repeatForever(autoreverses: false), value: isAnimating)
                  }

                  ZStack {
                      Text("Loading...")
                          .font(.title2.bold())
                          .foregroundColor(.gray.opacity(0.25))

                      Text("Loading...")
                          .font(.title2.bold())
                          .foregroundColor(.gray)
                          .mask(
                              Rectangle()
                                  .fill(
                                      LinearGradient(gradient: Gradient(colors: [.clear, .white.opacity(0.7), .clear]),
                                                     startPoint: .topLeading,
                                                     endPoint: .bottomTrailing)
                                  )
                                  .rotationEffect(.degrees(25))
                                  .offset(x: shimmer ? 250 : -250)
                          )
                          .animation(.linear(duration: 1.8).repeatForever(autoreverses: false), value: shimmer)
                  }
                  .frame(height: 30)

                  HStack(spacing: 10) {
                      ForEach(0..<3) { index in
                          Circle()
                              .fill(Color.customGreen)
                              .frame(width: 15, height: 15)
                              .scaleEffect(isAnimating ? 1.0 : 0.5)
                              .animation(Animation.easeInOut(duration: 0.6).repeatForever().delay(Double(index) * 0.2), value: isAnimating)
                      }
                  }
              }
              .padding()
          }
          .onAppear {
              isAnimating = true
              shimmer = true
          }
      }
}


