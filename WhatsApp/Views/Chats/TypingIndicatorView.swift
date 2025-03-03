
import SwiftUI

struct TypingIndicatorView: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 5) {
            Circle().frame(width: 8, height: 8)
            Circle().frame(width: 8, height: 8)
            Circle().frame(width: 8, height: 8)
        }
        .foregroundColor(.gray)
        .opacity(isAnimating ? 1.0 : 0.3)
        .animation(
            .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}
