//
//  CallRow.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 04/03/25.
//

import SwiftUI

struct CallRow: View {
    let call: Call

    var body: some View {
        HStack {
            Image(systemName: call.profileImage)
                .resizable()
                .scaledToFit()
                .frame(width: 45, height: 45)
                .foregroundColor(.gray)

            VStack(alignment: .leading, spacing: 4) {
                Text(call.contactName)
                    .font(.headline)

                HStack {
                    Image(systemName: call.callDirection == .incoming ?
                          (call.missedCall ? "phone.down.fill" : "phone.arrow.down.left.fill") :
                          "phone.arrow.up.right.fill")
                        .foregroundColor(call.missedCall ? .red : .gray)

                    Text("\(timeAgo(from: call.timestamp))")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    if call.callCount > 1 {
                        Text("(\(call.callCount))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.leading, 10)

            Spacer()

            Button(action: {
                print("Phone key is tapped")
            }) {
                Image(systemName: call.callType == .audio ? "phone" : "video")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 5)
    }

    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)

        if let day = components.day, day > 0 {
            return day == 1 ? "Yesterday" : "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute {
            return "\(minute)m ago"
        } else {
            return "Just now"
        }
    }
}

