//
//  CommunitiesView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 14/02/25.
//

// CommunitiesView.swift
import SwiftUI

struct CommunitiesView: View {
    var viewModel : CommunityViewModel
    @State private var showNewCommunity = false

    var body: some View {
        NavigationView {
            List {
                // New Community Section
                Section {
                    Button(action: {
                        showNewCommunity = true
                    }) {
                        HStack {
                            Image(systemName: "plus.square.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.gray)

                            Text("New Community")
                                .font(.headline)
                                .padding(.leading, 10)
                        }
                    }
                }

                // Communities Section
                Section {
                    ForEach(viewModel.communities) { community in
                        NavigationLink(destination: CommunityDetailView(community: community)) {
                            CommunityRow(community: community)
                        }
                    }
                }
            }
            .navigationTitle("Communities")
            .sheet(isPresented: $showNewCommunity) {
                NewCommunityView()
            }
        }
    }
}

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

struct CommunityDetailView: View {
    let community: Community

    var body: some View {
        List {
            // Community Info Section
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

            // Announcements Section
            Section(header: Text("Announcements")) {
                ForEach(community.announcements) { announcement in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(announcement.content)
                            .font(.subheadline)
                        HStack {
                            Text(announcement.sender)
                                .font(.caption)
                            Spacer()
                            Text(timeAgo(from: announcement.timestamp))
                                .font(.caption)
                        }
                        .foregroundColor(.gray)
                    }
                    .padding(.vertical, 5)
                }
            }

            // Groups Section
            Section(header: Text("Groups")) {
                ForEach(community.groups) { group in
                    GroupRow(group: group)
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

struct GroupRow: View {
    let group: CommunityGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(group.name)
                .font(.headline)
            HStack {
                Text("\(group.memberCount) members")
                    .font(.caption)
                Spacer()
                Text(timeAgo(from: group.timestamp))
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

struct NewCommunityView: View {
    @Environment(\.dismiss) var dismiss
    @State private var communityName = ""
    @State private var communityDescription = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Community Info")) {
                    TextField("Community Name", text: $communityName)
                    TextField("Description", text: $communityDescription)
                }
            }
            .navigationTitle("New Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        // Create community action
                        dismiss()
                    }
                    .disabled(communityName.isEmpty)
                }
            }
        }
    }
}

func timeAgo(from date: Date) -> String {
    let calendar = Calendar.current
    let now = Date()
    let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)

    if let day = components.day, day > 0 {
        return day == 1 ? "Yesterday" : "\(day)d ago"
    } else if let hour = components.hour, hour > 0 {
        return "\(hour)h ago"
    } else if let minute = components.minute {
        return "\(minute)m ago"
    } else {
        return "Just now"
    }
}

#Preview {
//    CommunitiesView(viewModel: communityViewModel)
}
