//
//  ChatRow.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 27/02/25.
//

import SwiftUI
import SwiftData
struct ChatRows: View {
    @Environment(ChatsViewModel.self) var chatsViewModel
    @Environment(\.modelContext) private var modelContext
    let user: User
    @State private var isProfilePicPresented = false
    var body: some View {
        NavigationLink(
            destination: ChatDetailView(user:user))
        {
            HStack {
                Button(
                    action: { isProfilePicPresented = true },
                    label: {
                    if let imageData = user.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                    }
                }
                )
                .buttonStyle(PlainButtonStyle()) // Removes button styling
                .popover(isPresented: $isProfilePicPresented) {
                    ProfilePicView(user: user)
                        .presentationDetents([.fraction(0.65)])
                }
                VStack(alignment: .leading) {
                    Text(user.name)
                        .font(.headline)
                    HStack{
                        Image(systemName: "checkmark.message.fill")
                            .foregroundColor(.green.opacity(0.6))
                        Text(user.lastChatMessage?.content ?? "Ok")
                            .font(.subheadline)
                            .lineLimit(1) // Limit to one line
                            .truncationMode(.tail)
                            .foregroundColor(.gray)
                    }.frame(maxWidth : .infinity, alignment: .leading)
                }
                Spacer()
                VStack {
                    let date: Date = Date()
                    Text(timeString(from: date))
                        .font(.caption)
                        .fontWeight(.light)
                        .foregroundStyle(.gray.opacity(0.8))
                }
            }
            .padding(.vertical,5)
            .cornerRadius(10)

        }
        .buttonStyle(.plain)
    }
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }


}

//#Preview {
//    ChatRow()
//}
