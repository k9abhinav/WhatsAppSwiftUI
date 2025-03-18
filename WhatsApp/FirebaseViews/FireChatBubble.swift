//
//  FireChatBubble.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 13/03/25.
//

import SwiftUI

struct FireChatBubble: View {
    let message: FireChatModel

    var body: some View {
        HStack(alignment: .bottom) {

            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                Text(message.content)
                    .padding(12)
                    .background(message.isFromCurrentUser ? Color.green : Color.gray.opacity(0.2))
                    .foregroundColor(message.isFromCurrentUser ? .white : .black)
                    .cornerRadius(16)
                    .font(.body)

                Text(timeString(from: message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(message.isFromCurrentUser ? .trailing : .leading, 4)

            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.95, alignment: message.isFromCurrentUser ? .trailing : .leading)

        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    
}
