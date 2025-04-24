//
//  CommunityDetailView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 04/03/25.
//

import SwiftUI

struct CommunityDetailView: View {
    @Environment(CommunityViewModel.self) var communityViewModel: CommunityViewModel
    let community: Community

    var body: some View {
        List {
            Section {
                VStack(alignment: .center, spacing: 10) {
                    Image(systemName: community.icon)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                        .padding(15)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Text(community.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(community.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    Text("\(community.memberCount) members")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            Section(header: Text("Announcements")) {
                ForEach(community.announcements) { announcement in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(announcement.content)
                            .font(.subheadline)
                        HStack {
                            Text(announcement.sender)
                                .font(.caption)
                            Spacer()
                            Text(communityViewModel.timeAgo(from: announcement.timestamp))
                                .font(.caption)
                        }
                        .foregroundColor(.gray)
                    }
                    .padding(.vertical, 5)
                }
            }
            Section(header: Text("Groups")) {
                ForEach(community.groups) { group in
                    CommunityGroupRow(group: group)
                        .environment(communityViewModel)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Community Settings", action: {})
                    Button("Add Members", action: {})
                    Button("Leave Community", action: {})
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
    }
}

