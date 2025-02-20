import SwiftUI
import PhotosUI

struct UserProfile {
    var name: String
    var status: String
    var profileImage: String?
}

class SettingsViewModel: ObservableObject {
    @Published var userProfile = UserProfile(
        name: "Abhinav",
        status: "Hey there, I am using WhatsApp!",
        profileImage: "abhinav"
    )

    func updateProfile(name: String? = nil, status: String? = nil, profileImage: String? = nil) {
        if let name = name { userProfile.name = name }
        if let status = status { userProfile.status = status }
        if let profileImage = profileImage { userProfile.profileImage = profileImage }
    }
}

// ------------------------------------ VIEW ----------------------------------------------------------

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showingEdit = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showingImageChangeAlert = false

    var body: some View {
        NavigationView {
            List {
                profileSection
                settingsSection
                actionsSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Image Changed", isPresented: $showingImageChangeAlert) {
                Button("OK", action: {})
            } message: {
                Text("Your profile image has been updated.")
            }
            .sheet(isPresented: $showingEdit) {
                EditProfileView(
                    nameValue: $viewModel.userProfile.name,
                    statusValue: $viewModel.userProfile.status
                )
            }
            .onChange(of: selectedPhoto) { _, newValue in
                loadImage(newValue)
            }
        }
    }

    private var profileSection: some View {
        Section {
            VStack(spacing: 15) {
                Text("My Profile")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(.black.opacity(0.8))

                PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                    ZStack {
                        profileImageView
                        Image(systemName: "camera.fill")
                            .padding(7)
                            .background(Color.green)
                            .clipShape(Circle())
                            .foregroundColor(.white.opacity(0.9))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                    .frame(width: 90, height: 90)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: { showingEdit = true }) {
                    VStack {
                        Text(viewModel.userProfile.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.black.opacity(0.8))
                        Text(viewModel.userProfile.status)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 5)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var profileImageView: some View {
        Group {
            if let selectedImageData = selectedImageData,
               let uiImage = UIImage(data: selectedImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else if let imageName = viewModel.userProfile.profileImage {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .foregroundColor(.gray)
            }
        }
    }

    private var settingsSection: some View {
        Section {
            RowView(iconSystemName: "key", title: "Account", subtitle: "Security, disappearing messages")
            RowView(iconSystemName: "lock", title: "Privacy", subtitle: "Block contacts, adjust privacy")
            RowView(iconSystemName: "message", title: "Chats", subtitle: "Themes, backup and restore chats")
            RowView(iconSystemName: "bell", title: "Notifications", subtitle: "Manage your notifications")
        }
    }

    private var actionsSection: some View {
        Section {
            Button("Logout") {}
            Button("About") {}
        }
        .foregroundColor(.red)
    }

    private func loadImage(_ newItem: PhotosPickerItem?) {
        Task {
            if let newItem = newItem, let data = try? await newItem.loadTransferable(type: Data.self) {
                await MainActor.run {
                    selectedImageData = data
                    viewModel.updateProfile(profileImage: "new_image")
                    showingImageChangeAlert = true
                }
            }
        }
    }
}

// ------------------------------------ COMPONENTS ----------------------------------------------------------

struct RowView: View {
    let iconSystemName: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            Image(systemName: iconSystemName)
                .frame(width: 32, height: 32)
                .foregroundColor(.blue)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 5)
    }
}

// ------------------------------------ EDIT PROFILE VIEW ----------------------------------------------------------

struct EditProfileView: View {
    @Binding var nameValue: String
    @Binding var statusValue: String
    @Environment(\.dismiss) var dismiss
    @State private var tempName: String = ""
    @State private var tempStatus: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information").font(.headline).padding(.bottom)) {

                    TextField("Enter your name", text: $tempName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 10)
                        .padding(.top,10)

                    TextField("Add About", text: $tempStatus)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }.listRowSeparator(.hidden)

            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        nameValue = tempName
                        statusValue = tempStatus
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear {
                tempName = nameValue
                tempStatus = statusValue
            }
        }
    }
}

// ------------------------------------ PREVIEW ----------------------------------------------------------

#Preview {
    SettingsView()
}
