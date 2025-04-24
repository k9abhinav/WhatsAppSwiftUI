import SwiftUI

struct ChatBubble: View {
    let message: Chat
    @Environment(UtilityClass.self) private var utilityVM : UtilityClass
    var body: some View {
        HStack(alignment: .bottom) {

            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                Text(message.content)
                    .padding(12)
                    .background(message.isFromCurrentUser ? Color.green : Color.gray.opacity(0.2))
                    .foregroundColor(message.isFromCurrentUser ? .white : .black)
                    .cornerRadius(16)
                    .font(.body)

                Text(utilityVM.timeStringShort(from: message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(message.isFromCurrentUser ? .trailing : .leading, 4)
                
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.95, alignment: message.isFromCurrentUser ? .trailing : .leading)

        }
    }


}
