//
//  CommunityRow.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 04/03/25.
//
import SwiftUI

struct CommunityRow: View {
    let community: Community

    var body: some View {
        HStack {
            Image(systemName: community.icon)
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.gray)
                .padding(8)
                .background(Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(community.name)
                    .font(.headline)
                Text("\(community.memberCount) members • \(community.groups.count) groups")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.leading, 10)
        }
        .padding(.vertical, 5)
    }
}
