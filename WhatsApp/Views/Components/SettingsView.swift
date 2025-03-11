import SwiftUI
import PhotosUI
import SwiftData

struct SettingsView: View {
    @State private var profileViewModel: ProfileImageViewModel = ProfileImageViewModel()
    @Environment(\.dismiss) var dismiss
    @Environment(AuthViewModel.self) private var viewModel
    @AppStorage("userName") private var userName = "User"
    @AppStorage("userStatus") private var userStatus = "No About here!"
    @AppStorage("userImageKey") private var userImageData: Data?
    @State private var showingEdit = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showingImageChangeAlert = false

    var body: some View {
        NavigationStack {
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
                    userName: $userName,
                    userStatus: $userStatus
                ).presentationDetents([.medium])
            }
            .onChange(of: selectedPhoto) { oldValue,newValue in
                loadImage(newValue)
            }
        }
    }

    // MARK: Components ----------------------------------------------

    private var profileSection: some View {
        Section {
            VStack(spacing: 15) {
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared())
                {
                    ZStack {
                        profileImageView
                        Image(systemName: "camera.fill")
                            .padding(7)
                            .background(Color.customGreen)
                            .clipShape(Circle())
                            .foregroundColor(.white.opacity(0.9))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                    .frame(width: 90, height: 90)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: { showingEdit = true }) {
                    VStack {
                        Text(viewModel.user?.fullName ?? "Couldn't load user name")
//                        Text(userName)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.black.opacity(0.8))
                            .padding(.bottom,6)
                        Text(userStatus)
                            .multilineTextAlignment(.center)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 5)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        } header: {
            Text("My Profile")
                .padding(.bottom, 5)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.secondary)
        }
    }

    private var profileImageView: some View {
        Group {
            if let imageData = profileViewModel.userImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
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
            eachSettingSection(iconSystemName: "key", title: "Account", subtitle: "Security, disappearing messages")
            eachSettingSection(iconSystemName: "lock", title: "Privacy", subtitle: "Block contacts, adjust privacy")
            eachSettingSection(iconSystemName: "message", title: "Chats", subtitle: "Themes, backup and restore chats")
            eachSettingSection(iconSystemName: "bell", title: "Notifications", subtitle: "Manage your notifications")
        }
    }

    private var actionsSection: some View {
        Section {
            Button("Logout") { viewModel.signOut() }
            Button("Delete your WhatsApp account") {
                Task {  await viewModel.deleteAccount()   }
            }
            Button("Update Password") {  }
            Button("Update Name") {}
            Button("About") {}
        }
        .foregroundColor(.red)
    }

    private func loadImage(_ newItem: PhotosPickerItem?) {
        Task {
            if let newItem = newItem,
               let data = try? await newItem.loadTransferable(type: Data.self) {
                await MainActor.run {
                    userImageData = data
                    showingImageChangeAlert = true
                }
            }
        }
    }
}

struct eachSettingSection: View {
    let iconSystemName: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            Image(systemName: iconSystemName)
                .frame(width: 32, height: 32)
                .foregroundColor(.secondary)
            Spacer()
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 3)
    }
}




