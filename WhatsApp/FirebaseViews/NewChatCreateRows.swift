import SwiftUI

struct NewChatCreateRows: View {
    let imageSysName: String
    let text: String
    var body: some View {
        HStack {
            Image(systemName: imageSysName)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundStyle(Color.customGreen)
            Spacer()
            Text(text)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
    }
}
