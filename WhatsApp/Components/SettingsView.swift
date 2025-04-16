//
//  SettingsView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 08/04/25.
//


import SwiftUI
import PhotosUI
import SwiftData

struct SettingsView: View {
    @Environment(ContactsManager.self) private var contactsManager: ContactsManager
    @Environment(\.dismiss) var dismiss
    @Environment(FireAuthViewModel.self) private var viewModel : FireAuthViewModel
    @Environment(FireUserViewModel.self) private var userViewModel: FireUserViewModel
    @State private var userId: String?
    @AppStorage("userName") private var userName = "Error~User"
    @AppStorage("userStatus") private var userStatus = "No~data!"
    @State private var userImageURLString: String?
    @Binding var selectView: Bool
    @State var istoggleOn: Bool = false
    @State private var showingEdit = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showingImageChangeAlert = false
    var body: some View {
        VStack {
            List {
                profileSection
                toggeleViewSection
                settingsSection
                actionsSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar{
                ToolbarItem(placement: .topBarLeading){ backButton }
            }
            .alert("Image Changed", isPresented: $showingImageChangeAlert) {
                Button("OK", action: {  })
            } message: { Text("Your profile image has been updated. Please wait it a moment to see the changes.") }
                .sheet(isPresented: $showingEdit) {
                    EditProfileView(
                        user: viewModel.currentLoggedInUser!,
                        userName: $userName,
                        userStatus: $userStatus
                    ).presentationDetents([.medium])
                }
                .onChange(of: userViewModel.triggerProfilePicUpdated) { oldValue, newValue in
                    if let imageUrlString = viewModel.currentLoggedInUser?.imageUrl, let imageUrl = URL(string: imageUrlString) {
                        print("Loading image from URL....")
                        loadImageFromURL(imageUrl)
                    }
                }
                .onAppear {
                    userId = viewModel.currentLoggedInUser?.id
                    userName = viewModel.currentLoggedInUser?.name ?? "Error in loading user name"
                    userStatus = viewModel.currentLoggedInUser?.aboutInfo ?? ""
                    if let imageUrlString = viewModel.currentLoggedInUser?.imageUrl, let imageUrl = URL(string: imageUrlString) {
                        loadImageFromURL(imageUrl)
                    }
                }
                .onChange(of: showingEdit) { oldValue, newValue in
                    Task{
                        await viewModel.loadCurrentUser()
                        userName = viewModel.currentLoggedInUser?.name ?? "Error in loading user name"
                        userStatus = viewModel.currentLoggedInUser?.aboutInfo ?? ""
                    }
                }
        }
    }
    
    // MARK: Components ----------------------------------------------
    private var backButton: some View {
        Button(
            action: { dismiss() }
        )
        {  Image(systemName: "arrow.backward")  }
        
    }
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
    private var toggeleViewSection: some View {
        Section {
            Toggle(isOn: $istoggleOn) {
                Text("Toggle Views")
            }
            .onChange(of: istoggleOn){ old, new in
                selectView.toggle()
            }
            Button(action: {
                contactsManager.requestAccess()
            }, label: {
                Text("Load All Contacts As Users")
            }
            )
        } header: {
            Text("Toggle Your View Mode")
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
            photoLibrary: .shared()
        ) {
            ZStack { profileImageView; cameraIconOverlay }
                .frame(width: 90, height: 90)
        }
        .buttonStyle(PlainButtonStyle())
        .onChange(of: selectedPhoto) { oldItem, newItem in
            if let newItem = newItem {
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        
                        // Upload Image and Get New URL
                        if let newImageUrl = await userViewModel.changeProfileImage(userId: userId ?? "", image: uiImage) {
                            await MainActor.run {
                                userImageURLString = newImageUrl
                            }
                        }
                    }
                }
            }
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
        AsyncImage(url: URL(string: userImageURLString ?? "")) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: 80, height: 80)
                
            case .success(let image):
                image.resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                
            case .failure:
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .foregroundColor(.gray)
                
            @unknown default:
                EmptyView()
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
            if viewModel.typeOfAuth == .email {
                Button("Update Password") {  }
                Button("Update Name") {}
            } else if viewModel.typeOfAuth == .phone {
                Button("Delete your phone number") {}
            }
            Button("Connect with other Meta accounts") {}
        }
    }
    private func loadAllContacts(){
        contactsManager.requestAccess()
    }
    private func loadImageFromURL(_ url: URL) {
        Task {
            await MainActor.run {
                userImageURLString = url.absoluteString
            }
        }
    }
    
}






