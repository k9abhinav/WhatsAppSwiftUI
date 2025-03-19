import SwiftUI
import PhotosUI
import SwiftData

struct SettingsView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(AuthViewModel.self) private var viewModel
    @Environment(FireUserViewModel.self) private var userViewModel: FireUserViewModel
    @State private var userId: String?
    @AppStorage("userName") private var userName = "Error~User"
    @AppStorage("userStatus") private var userStatus = "No~data!"
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
            .alert("Image Changed", isPresented: $showingImageChangeAlert) {
                Button("OK", action: {})
            } message: { Text("Your profile image has been updated.") }
            .sheet(isPresented: $showingEdit) {
                EditProfileView(
                    user: viewModel.fireuser!,
                    userName: $userName,
                    userStatus: $userStatus
                ).presentationDetents([.medium])
            }
            .onChange(of: selectedPhoto) { oldValue,newValue in
                loadImage(newValue)
            }
            .onAppear {
                userId = viewModel.fireuser?.id
                userName = viewModel.fireuser?.name ?? "Error in loading user name"
                userStatus = viewModel.fireuser?.aboutInfo ?? ""
                userImageData = viewModel.fireuser?.imageUrl?.data(using: .utf8)
            }
        }
    }

    // MARK: Components ----------------------------------------------

    private var profileSection: some View {
        Section {
            VStack(spacing: 15) {
                profileImageAndEditView
                userDetailsAndEditButton
            }
            .frame(maxWidth: .infinity, alignment: .center)
        } header: {
            Text("My Profile")
                .padding(.bottom, 5)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.secondary)
        }
    }
    private var userDetailsAndEditButton: some View {
        Button(action: { showingEdit = true }) {
            VStack(spacing:10) {
                Text( userName )
//                        Text(userName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.black.opacity(0.8))
                Text(userStatus)
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.top, 5)
        }
    }
    private var profileImageAndEditView: some View {
        PhotosPicker(
            selection: $selectedPhoto,
            matching: .images,
            photoLibrary: .shared())
        {
            ZStack { profileImageView; cameraIconOverlay }
            .frame(width: 90, height: 90)
        }
        .buttonStyle(PlainButtonStyle())
        .onChange(of: selectedPhoto) { oldItem,newItem in
//            if let newItem = newItem {
//                Task {
//                    if let data = try? await newItem.loadTransferable(type: Data.self),
//                       let uiImage = UIImage(data: data) {
//                        await userViewModel.changeProfileImage(userId: userId ?? "", image: uiImage)
//                    }
//                }
//            }

        }
    }
    
    private var cameraIconOverlay: some View {
        Image(systemName: "camera.fill")
            .padding(7)
            .background(Color.customGreen)
            .clipShape(Circle())
            .foregroundColor(.white.opacity(0.9))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
    private var profileImageView: some View {
        Group {
            if let imageData = userImageData, let uiImage = UIImage(data: imageData) {
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
            EachSettingSection(iconSystemName: "key", title: "Account", subtitle: "Security, disappearing messages")
            EachSettingSection(iconSystemName: "lock", title: "Privacy", subtitle: "Block contacts, adjust privacy")
            EachSettingSection(iconSystemName: "message", title: "Chats", subtitle: "Themes, backup and restore chats")
            EachSettingSection(iconSystemName: "bell", title: "Notifications", subtitle: "Manage your notifications")
            EachSettingSection(iconSystemName: "globe", title: "App Language", subtitle: "English (device's langauage)")
            EachSettingSection(iconSystemName: "questionmark.circle", title: "Help", subtitle: "Help Centre, contact us")
            EachSettingSection(iconSystemName: "iphone.gen3.badge.exclamationmark", title: "App Updates", subtitle: "Check for updates")
        }
            }

    private var actionsSection: some View {
        Section {
            Group{
                Button("Logout") { viewModel.signOut() }
                Button("Delete your WhatsApp account") {
                    Task {  await viewModel.deleteAccountandUser()   }
                }
            }
            .foregroundColor(.red)
            if viewModel.authType == .email {
                Button("Update Password") {  }
                Button("Update Name") {}
            } else if viewModel.authType == .phone {
                Button("Delete your phone number") {}
            }
            Button("Connect with other Meta accounts") {}
        }
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






