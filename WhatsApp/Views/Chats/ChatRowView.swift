//
//  ChatsView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 13/02/25.
//
//resizable(): Makes the image scalable.
//scaledToFit(): Scales the image to fit within the frame.
//frame(width:height:): Sets the size of the frame to 200x200 points.

//If you create an ObservableObject class with a @Published property, you can access and observe changes to that property in another view using @StateObject (or @ObservedObject if the object is passed down).

// ChatsRowView.swift
import SwiftUI
import Contacts
//import AVFoundation // Import for camera access

struct ChatRowView: View {
    @EnvironmentObject private var contactsManager: ContactsManager
    @State private var searchText = ""
    @State private var showingSettings = false
    @State private var isShowingScanner = false
    @State private var isShowingCamera = false

    var filteredContacts: [Contact] {
        guard !searchText.isEmpty else {
            return contactsManager.contacts
        }

        return contactsManager.contacts.filter { contact in
            let searchTerms = searchText.lowercased().trimmingCharacters(in: .whitespaces)
            return contact.name.lowercased().contains(searchTerms) ||
            contact.phone.replacingOccurrences(of: " ", with: "")
                .contains(searchTerms.replacingOccurrences(of: " ", with: ""))
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack{
                        CustomSearchBar(searchText: $searchText)
                    }
                    .cornerRadius(20)
                    .padding(.horizontal,8)
                    .padding(.top,12)
                    VStack(spacing: 15) {
                        if filteredContacts.isEmpty && !searchText.isEmpty {
                            Text("No matches found")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding()
                        } else if filteredContacts.isEmpty && searchText.isEmpty {
                            Text("No Contacts Found")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            ForEach(filteredContacts) { contact in
                                ChatRow(contact: contact)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 50)
                }
              
                .scrollIndicators(.hidden)
                .scrollContentBackground(.hidden)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Text("WhatsApp")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isShowingScanner = true
                            print("Showing Scanner")
                        } label: {
                            Image(systemName: "qrcode.viewfinder")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            isShowingCamera = true
                            print("Showing Camera")
                        }) {
                            Image(systemName: "camera")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            showingSettings = true
                            print("Showing Settings")
                        }) {
                            Image(systemName: "ellipsis")
                                .rotationEffect(.degrees(90))
                        }
                    }
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
                //                .searchable(text: $searchText, placement: .automatic, prompt: "Search Contacts")
                .scrollIndicators(.hidden)
                .background(.white)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(.white, for: .navigationBar)
                .toolbarColorScheme(.light, for: .navigationBar)
            }
            .onAppear {
                contactsManager.requestAccess()
            }
        }

    }

    struct CustomSearchBar: View {
        @Binding var searchText: String

        var body: some View {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 10)
                    .frame(width: 30, height: 30)

                TextField("Ask Meta AI or Contacts", text: $searchText)
                    .padding(.vertical, 10)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .background(Color.gray.opacity(0.1))

        }
    }

    struct ProfilePicView: View {
        let contact: Contact
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            VStack {
                if let imageData = contact.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        .background(Color.black.opacity(0.9))
                        .ignoresSafeArea()
                } else {
                    Image(systemName: "person.crop.circle.fill") // Default image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                }
            }
            .onTapGesture {
                dismiss()
            }
        }
    }


    struct ChatRow: View {
        let contact: Contact
        @State private var isProfilePicPresented = false
        @EnvironmentObject private var navigationState: NavigationState

        var body: some View {
            NavigationLink(
                destination: ChatDetailView(contact: contact)
                .onAppear { navigationState.isChatDetailActive = true }
                .onDisappear { navigationState.isChatDetailActive = false }
            ) {
                HStack {
                    Button(action: { isProfilePicPresented = true },
                           label: {
                        if let imageData = contact.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.gray)
                        }
                    }

                    ).buttonStyle(PlainButtonStyle()) // Removes button styling
                        .sheet(isPresented: $isProfilePicPresented) {
                            ProfilePicView(contact: contact)
                        }

                    VStack(alignment: .leading) {
                        Text(contact.name)
                            .font(.headline)

                        Text(contact.phone)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Spacer()
                    VStack {
                        let date: Date = Date()
                        Text(timeString(from: date))
                            .font(.caption)
                            .fontWeight(.light)
                            .foregroundStyle(.gray.opacity(0.8))
                    }
                }
                .padding(.vertical,5)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        private func timeString(from date: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }

}
//#Preview {
//    ChatRowView( contact: .init(name: "John Doe", phone: "+1234567890", imageData: nil))
//}
