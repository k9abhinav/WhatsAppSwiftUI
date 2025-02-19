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
        status: "Anytime available!",
        profileImage: "abhinav"
    )

    func updateProfile(name: String? = nil, status: String? = nil, profileImage: String? = nil) {
        if let name = name {
            userProfile.name = name
        }
        if let status = status {
            userProfile.status = status
        }
        if let profileImage = profileImage {
            userProfile.profileImage = profileImage
        }
    }
}

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showingNameEdit = false
    @State private var showingStatusEdit = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showingImageChangeAlert = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(spacing: 15) {
                        if let selectedImageData = selectedImageData, let uiImage = UIImage(data: selectedImageData) {
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
                        }

                        PhotosPicker(
                            selection: $selectedPhoto,
                            matching: .images,
                            photoLibrary: .shared()) {
                                EmptyView()
                            }
                            .frame(width: 0, height: 0)
                            .clipped()

                        VStack(alignment: .leading, spacing: 8) {
                            Text(viewModel.userProfile.name)
                                .font(.title3)
                                .fontWeight(.semibold)

                            Text(viewModel.userProfile.status)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 10)
                }

                Section {
                    Button(action: { showingNameEdit = true }) {
                        HStack {
                            Label("Name", systemImage: "person")
                            Spacer()
                            Text(viewModel.userProfile.name)
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }

                    Button(action: { showingStatusEdit = true }) {
                        HStack {
                            Label("Status", systemImage: "message")
                            Spacer()
                            Text(viewModel.userProfile.status)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: selectedPhoto) { oldValue, newValue in
            print("Photo selection changed")
            Task {
                if let newItem = newValue {
                    print("New photo item selected")
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        print("Successfully loaded image data")
                        // Update the image data first
                        await MainActor.run {
                            selectedImageData = data
                        }

                        // Update the profile and show alert
                        if let uiImage = UIImage(data: data) {
                            print("Successfully created UIImage")
                            // Update profile with a default identifier if none exists
                            let identifier = uiImage.accessibilityIdentifier ?? "profile_image"
                            await MainActor.run {
                                viewModel.updateProfile(profileImage: identifier)
                                print("Showing alert now")
                                showingImageChangeAlert = true
                            }
                        }
                    } else {
                        print("Failed to load image data")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNameEdit) {
            EditProfileView(title: "Name", value: $viewModel.userProfile.name)
        }
        .sheet(isPresented: $showingStatusEdit) {
            EditProfileView(title: "Status", value: $viewModel.userProfile.status)
        }
        .alert("Image Changed", isPresented: $showingImageChangeAlert) {
            Button("OK", action: {})
        } message: {
            Text("Your profile image has been updated.")
        }
    }
}

struct EditProfileView: View {
    let title: String
    @Binding var value: String
    @Environment(\.dismiss) var dismiss
    @State private var tempValue: String = ""

    var body: some View {
        NavigationView {
            VStack {
                TextField(title, text: $tempValue)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        value = tempValue
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            tempValue = value
        }
    }
}

#Preview {
    SettingsView()
}
