//
//  UpdatesDetailView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 14/02/25.
//

// StatusView.swift
import SwiftUI

struct StatusView: View {
    @StateObject private var viewModel = StatusViewModel()
    //Creates a instance of Observable object
//    This initialization happens only once when the view first appears
//    @StateObject ensures that the ObservableObject instance is retained (kept alive) as long as the view is displayed.
//    Even if the view re-renders (due to state changes or other UI updates), the same ObservableObject instance is used.
//  @StateObject automatically observes any changes to @Published properties within your ObservableObject.  When a @Published property changes, SwiftUI updates the views that depend on it.

    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        ZStack(alignment: .bottomTrailing) {
                            Image(systemName: viewModel.statuses[0].profileImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())

                            Circle()
                                .fill(Color.green)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                )
                                .offset(x: 3, y: 3)
                        }

                        VStack(alignment: .leading) {
                            Text("My Status")
                                .font(.headline)
                            Text("Tap to add status update")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.leading, 10)
                    }
                    .padding(.vertical, 5)
                } header: {
                    Text("Recent Updates")
                }

                // Recent Updates
                Section {
                    // DropFirst to drop the first element in the array.
                    ForEach(viewModel.statuses.dropFirst()) { status in
                        StatusRow(status: status)
                    }
                }
            }
            .navigationTitle("Status")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("Camera Action")
                    }) {
                        Image(systemName: "camera")
                            .foregroundColor(.gray)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 10)
                }

            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }.background(Color.white)

        }
    }
}

struct StatusRow: View {
    let status: Status

    var body: some View {
        HStack {

            Circle()
                .stroke(status.isViewed ? Color.gray : Color.green, lineWidth: 2)
                .frame(width: 65, height: 65)
                .overlay(
                    Image(systemName: status.profileImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 55, height: 55)
                        .clipShape(Circle())
                )

            VStack(alignment: .leading) {
                Text(status.user)
                    .font(.headline)
                Text(timeAgo(from: status.timePosted))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.leading, 10)

            Spacer()
        }
        .padding(.vertical, 5)
    }

    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour], from: date, to: now)

        if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute {
            return "\(minute)m ago"
        } else {
            return "Just now"
        }
    }
}

// Preview
struct StatusView_Previews: PreviewProvider {
    static var previews: some View {
        StatusView()
    }
}
