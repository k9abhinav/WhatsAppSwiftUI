import SwiftUI
import PhotosUI
import SwiftData


struct UserProfile {
    var name: String
    var status: String
    var profileImage: String?
}

@Observable class SettingsViewModel {
     var userProfile = UserProfile(
        name: "User",
        status: "Add About Here!",
        profileImage: "person.circle.fill"
    )

    func updateProfile(name: String? = nil, status: String? = nil, profileImage: String? = nil) {
        if let name = name { userProfile.name = name }
        if let status = status { userProfile.status = status }
        if let profileImage = profileImage { userProfile.profileImage = profileImage }
    }
}

// ------------------------------------ VIEW ----------------------------------------------------------

struct SettingsView: View {

    //    @StateObject private var viewModel = SettingsViewModel()
    @AppStorage("userName") private var userName = "User"
    @AppStorage("userStatus") private var userStatus = "No About here!"
    @AppStorage("userImageKey") private var userImageData: Data?

    @Environment(\.dismiss) var dismiss
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
            .onChange(of: selectedPhoto) { _, newValue in
                loadImage(newValue)
            }
        }
    }

    private var profileSection: some View {
        Section {



            VStack(spacing: 15) {


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
                        Text(userName)
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
            if let imageData = userImageData,
               let uiImage = UIImage(data: imageData) {
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
        .foregroundColor(.secondary)
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

// ------------------------------------ COMPONENTS ----------------------------------------------------------

struct RowView: View {
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

// ------------------------------------ EDIT PROFILE VIEW ----------------------------------------------------------

struct EditProfileView: View {
    @Binding var userName: String
    @Binding var userStatus: String
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
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") { dismiss() }
//                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        userName = tempName
                        userStatus = tempStatus
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear {
                tempName = userName
                tempStatus = userStatus
            }
        }
    }
}

// ------------------------------------ PREVIEW ----------------------------------------------------------

#Preview {
    SettingsView()
}
