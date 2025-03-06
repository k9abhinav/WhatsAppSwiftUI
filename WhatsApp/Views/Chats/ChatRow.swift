
import SwiftUI
import SwiftData

struct ChatRow: View {

    let user: User
    @State private var isProfilePicPresented = false

    var body: some View {
        NavigationLink( destination: ChatDetailView(user:user) )
        {
            HStack {
                Button(
                    action: { isProfilePicPresented.toggle() },
                    label: { userProfilePictureView }
                ).buttonStyle(PlainButtonStyle())
                    .popover(isPresented: $isProfilePicPresented) {
                        ProfilePicView(user: user).presentationDetents([.fraction(0.65)])
                    }
                userProfileNameandContent
                Spacer()
                userLastSeenTime
            }
            .padding(.vertical,5)
            .cornerRadius(10)

        }
        .buttonStyle(.plain)
    }
    // MARK: SUB-COMPONENTS -----
    private var userLastSeenTime: some View {
        VStack {
            let date: Date = user.lastChatMessage?.timestamp ??  .now
            Text(timeString(from: date))
                .font(.caption)
                .fontWeight(.light)
                .foregroundStyle(.gray.opacity(0.8))
        }
    }
    private var userProfileNameandContent: some View {
        VStack(alignment: .leading) {
            Text(user.name)
                .font(.headline)
            HStack{
                Image(systemName: "checkmark.message.fill")
                    .foregroundColor(.green.opacity(0.9))
                Text(user.lastChatMessage?.content ?? "")
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.gray)
            }.frame(maxWidth : .infinity, alignment: .leading)
        }
    }
    private var userProfilePictureView: some View {
        Group{
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
    }
    // MARK: HELPER FUNCTIONS -------------------------------
    private func timeString(from date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
            return formatter.string(from: date)  // Example: "2:30 PM"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)  // Example: "Mar 4, 2025"
        }
    }



}
