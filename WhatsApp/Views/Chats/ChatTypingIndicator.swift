
import SwiftUI

struct ChatTypingIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        HStack{
            HStack(spacing: 5) {
                Circle().frame(width: 8, height: 8)
                Circle().frame(width: 8, height: 8)
                Circle().frame(width: 8, height: 8)
            }
            .foregroundColor(.gray)
            Text("Typing...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth:.infinity, maxHeight:30,alignment: .leading)
        .opacity(isAnimating ? 1.0 : 0.3)
        .onAppear {
            withAnimation(.bouncy) {
                isAnimating = true
            }
        }
    }
}
