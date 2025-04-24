//
//  FireUpdates.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 15/04/25.
//

import SwiftUI

import SwiftUI

struct FireUpdatesView: View {
    @Environment(FireUserViewModel.self) private var userViewModel
    @Environment(FireAuthViewModel.self) private var authViewModel
    @Environment(FireUpdateViewModel.self) var updateViewModel: FireUpdateViewModel

    let userId: String

    var user: FireUserModel {
        userViewModel.allUsers.first { $0.id == userId } ?? FireUserModel(name: "Unknown")
    }

    @State private var showingAddUpdateSheet = false
    @State private var showingStoryViewer = false
    @State private var selectedUpdateIndex = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // MARK: - Add Update Button
                    Button(action: { showingAddUpdateSheet = true }) {
                        HStack {
                            ZStack(alignment: .bottomTrailing) {
                                userProfilePictureView
                                    .frame(width: 60, height: 60)

                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .font(.system(size: 18))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("My Updates")
                                    .fontWeight(.semibold)
                                Text("Add to My Updates")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 1)
                        .padding(.horizontal)
                    }


                    // MARK: - My Status
                    let myUpdates = updateViewModel.getUpdatesForUser(userId: userId)
                    if !myUpdates.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("My Status")
                                .font(.headline)
                                .padding(.horizontal)
                                .foregroundColor(.gray)

                            StoryUserRowView(user: user, updates: myUpdates)
                                .padding(.horizontal)
                        }
                    }

                    // MARK: - Others' Updates
                    let otherUsers = updateViewModel.usersWithUpdates.filter { $0 != userId }

                    if !otherUsers.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recent Updates")
                                .font(.headline)
                                .padding(.horizontal)
                                .foregroundColor(.gray)

                            LazyVStack(spacing: 16) {
                                ForEach(otherUsers, id: \.self) { otherUserId in
                                    let updates = updateViewModel.getUpdatesForUser(userId: otherUserId)
                                    if !updates.isEmpty {
                                        let updateUser = userViewModel.allUsers.first { $0.id == otherUserId } ?? FireUserModel(name: "Unknown")
                                        StoryUserRowView(user: updateUser, updates: updates)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }

                    if updateViewModel.allUpdates.isEmpty {
                        ContentUnavailableView("No Updates",
                                               systemImage: "bubble.left.and.text.bubble.right",
                                               description: Text("All updates in the last 24 hours will appear here."))
                            .padding(.top)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Updates")
            .sheet(isPresented: $showingAddUpdateSheet) {
                FireAddUpdateView(userId: userId)
            }
            .onAppear {
                updateViewModel.setupUpdatesListener()
                userViewModel.setupUsersListener()
                updateViewModel.scheduleCleanupTask()
            }
            .alert(item: Binding(
                get: { updateViewModel.error != nil ? updateViewModel.error! : nil },
                set: { updateViewModel.error = $0 }
            )) { errorMessage in
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    ///
    private var userProfilePictureView: some View {
        Group {
            if let imageUrlString = authViewModel.currentLoggedInUser?.imageUrl, let imageUrl = URL(string: imageUrlString) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        DefaultProfileImage(size: 50)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50,height: 50)
                            .clipShape(Circle())

                    case .failure:
                        DefaultProfileImage(size: 50)
                    @unknown default:
                        EmptyView()
                            .frame(width: 50,height: 50)
                    }
                }

            }
            else{
                DefaultProfileImage(size: 50)
            }
        }
    }
}


//#Preview {
//    @Previewable @State var userVM = FireUserViewModel()
//    @Previewable @State var updateVM = FireUpdateViewModel()
//    FireUpdatesView( userId: "1")
//        .environment(userVM)
//        .environment(updateVM)
//}
