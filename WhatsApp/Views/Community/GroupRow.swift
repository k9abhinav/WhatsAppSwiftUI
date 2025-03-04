//
//  GroupRow.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 04/03/25.
//

import SwiftUI

struct GroupRow: View {
    @Environment(CommunityViewModel.self) var viewModel:CommunityViewModel
    let group: CommunityGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(group.name)
                .font(.headline)
            HStack {
                Text("\(group.memberCount) members")
                    .font(.caption)
                Spacer()
                Text(viewModel.timeAgo(from: group.timestamp))
                    .font(.caption)
            }
            .foregroundColor(.gray)

            Text(group.lastMessage)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 5)
    }
}
