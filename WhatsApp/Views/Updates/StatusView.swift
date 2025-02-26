//
//  StatusView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 26/02/25.
//
import SwiftUI
import SwiftData
import PhotosUI


//------------------------------------------------------------------------------------ View
struct StatusView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Status.createdAt, order: .reverse) private var allStatuses: [Status]

     var activeStatuses: [Status] {
         let now = Date() // Compute current time at the moment of access
         return allStatuses.filter { $0.expiresAt > Date() }
     }


    @State private var showingAddStatus = false
    @State private var selectedStatus: Status?

    var body: some View {
        NavigationStack {
            ZStack {
                if activeStatuses.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "circle.dashed")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No Status Updates")
                            .font(.headline)

                        Text("Tap the + button to add a status update")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: {
                            showingAddStatus = true
                        }) {
                            Text("Add Status")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.top, 8)
                    }
                } else {
                    List {
                        Section(header: Text("My Status")) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 2)
                                        .frame(width: 50, height: 50)

                                    if let imageData = activeStatuses.first?.imageData, let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 46, height: 46)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.gray)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("My Status")
                                        .font(.headline)
                                        .padding(.bottom, 8)

                                    Text("\(activeStatuses.count) updates")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button(action: {
                                    showingAddStatus = true
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if !activeStatuses.isEmpty {
                                    selectedStatus = activeStatuses.first
                                }
                            }
                        }

                        Section(header: Text("My Recent Updates").padding(.bottom, 8)) {
                            ForEach(activeStatuses) { status in
                                StatusRowView(status: status)
                                    .onTapGesture {
                                        selectedStatus = status
                                    }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Status Updates")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingAddStatus = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddStatus) {
                AddStatusView()
            }
            .sheet(item: $selectedStatus) { status in
                StatusDetailView(status: status)
            }
            .task {
                cleanupExpiredStatuses()
            }
        }
    }

    private func cleanupExpiredStatuses() {
        let now = Date()

        Task {
            do {

                let allStatuses = try modelContext.fetch(FetchDescriptor<Status>())


                let expiredStatuses = allStatuses.filter { $0.expiresAt <= now }


                for status in expiredStatuses {
                    modelContext.delete(status)
                }

                try modelContext.save()
            } catch {
                print("Failed to clean up expired statuses: \(error)")
            }
        }
    }

}

#Preview {
    StatusView()
}
