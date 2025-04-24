
import SwiftUI

struct EachSettingSection: View {
    let iconSystemName: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack {
            Image(systemName: iconSystemName)
                .frame(width: 32, height: 32)
                .foregroundColor(.secondary)
            Spacer()
            VStack(alignment: .leading,spacing: 5) {
                Text(title)
                    .font(.subheadline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

