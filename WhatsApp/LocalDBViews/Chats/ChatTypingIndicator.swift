import SwiftUI

struct ChatTypingIndicator: View {
    @State private var isTyping = false
    @State private var animateDot1 = false
    @State private var animateDot2 = false
    @State private var animateDot3 = false

    var body: some View {
        HStack(alignment: .bottom) {
            HStack(spacing: 6) {
                // Typing dots
                Circle()
                    .frame(width: 8, height: 8)
                    .scaleEffect(animateDot1 ? 1 : 0.5)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(0), value: animateDot1)

                Circle()
                    .frame(width: 8, height: 8)
                    .scaleEffect(animateDot2 ? 1 : 0.5)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(0.2), value: animateDot2)

                Circle()
                    .frame(width: 8, height: 8)
                    .scaleEffect(animateDot3 ? 1 : 0.5)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(0.4), value: animateDot3)
            }
            .foregroundColor(.white)
            .padding(10)
            .background(Color.gray.opacity(0.6))
            .clipShape(Capsule())
            .scaleEffect(isTyping ? 1 : 0.8)
            .opacity(isTyping ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isTyping)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 5)
        .onAppear {
            isTyping = true
            animateDot1 = true
            animateDot2 = true
            animateDot3 = true
        }
    }
}
#Preview {
    ChatTypingIndicator()
}