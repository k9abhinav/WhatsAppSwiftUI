//
//  MessageBubble.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 27/02/25.
//

import SwiftUI

struct MessageBubble: View {
    let message: Chat

    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
            }

            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading) {
              Group {
                  Text(message.content)
                      .padding(12)
//                      .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
                      .background(message.isFromCurrentUser ? Color.green : Color.gray.opacity(0.2))
                      .foregroundColor(message.isFromCurrentUser ? .white : .black)
                      .cornerRadius(16)

                  Text(timeString(from: message.timestamp))
                      .font(.caption2)
                      .foregroundColor(.gray)
                }

            }

            if !message.isFromCurrentUser {
                Spacer()
            }
        }
        .frame(maxWidth:.infinity)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

//#Preview {
//    MessageBubble()
//}
