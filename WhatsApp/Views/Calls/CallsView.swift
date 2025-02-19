//
//  CallsView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 13/02/25.
//

// CallsView.swift
import SwiftUI

struct CallsView: View {
    @StateObject private var viewModel = CallsViewModel()
    @State private var showNewCallSheet = false

    var body: some View {
        NavigationView {
            List {
                // Create Call Link Section
                Section {
                    HStack {
                        Image(systemName: "link")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .foregroundColor(.green)
                            .padding(8)
                            .background(Color.green.opacity(0.2))
                            .clipShape(Circle())

                        VStack(alignment: .leading) {
                            Text("Create call link")
                                .font(.headline)
                            Text("Share a link for your WhatsApp call")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.leading, 10)
                    }
                    .padding(.vertical, 5)
                }

                // Recent Calls Section
                Section(header: Text("Recent")) {
                    ForEach(viewModel.calls) { call in
                        CallRow(call: call)
                    }
                }
            }
            .navigationTitle("Calls")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showNewCallSheet = true
                    }) {
                        Image(systemName: "phone.badge.plus")
                            .foregroundColor(.green)
                    }
                }
            }
            .sheet(isPresented: $showNewCallSheet) {
                NewCallView()
            }
        }
    }
}

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

struct NewCallView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("New Call To")) {
                    ForEach(["Alice", "Bob", "Charlie"], id: \.self) { contact in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.gray)

                            Text(contact)
                                .padding(.leading, 10)

                            Spacer()

                            HStack(spacing: 20) {
                                Button(action: {
                                    // Make audio call
                                }) {
                                    Image(systemName: "phone")
                                        .foregroundColor(.green)
                                }

                                Button(action: {
                                    // Make video call
                                }) {
                                    Image(systemName: "video")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Contact")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search contacts")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CallsView()
}
