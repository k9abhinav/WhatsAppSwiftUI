//  ChatsView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 13/02/25.

import SwiftUI
import Contacts
import PhotosUI
import SwiftData

struct ChatRowView: View {
    
    @State var viewModel:  ChatsViewModel
    @Query private var users: [User]
    @State private var isShowingScanner = false

// ------------------------------MARK: BODY VIEW ------------------------------------------------------------
    var body: some View {
        NavigationStack {
            VStack {
                scrollViewChatUsers
                    .scrollIndicators(.hidden)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            whatsAppTitle
                        }
                        ToolbarItemGroup {
                            PhotosPicker(
                                selection: .constant(nil),
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Image(systemName: "qrcode.viewfinder")
                            }
                            PhotosPicker(
                                selection: .constant(nil),
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Image(systemName: "camera")
                            }
                            Button(
                                action: {
                                    viewModel.toggleSettings()
                            }
                            ) {
                                Image(systemName: "ellipsis")
                                    .rotationEffect(.degrees(90))
                            }
                        }
                    }
                    .sheet(isPresented: $viewModel.showingSettings) {
                        SettingsView()
                    }
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(.white, for: .navigationBar)
                    .toolbarColorScheme(.light, for: .navigationBar)
            }
        }
    }
    
    private var whatsAppTitle: some View {
        Text("WhatsApp")
            .font(.title)
            .fontWeight(.semibold)
            .foregroundStyle(.green)
    }
    private var scrollViewChatUsers: some View {
        ScrollView {
            VStack {
                CustomSearchBar(searchText: $viewModel.searchText)
            }
            .cornerRadius(20)
            .padding(.horizontal,8)
            .padding(.top,12)

            VStack(spacing: 17) {
                let filtered = viewModel.filteredUsers(users: users)
                if filtered.isEmpty && !viewModel.searchText.isEmpty {
                    Text("No matches found")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding()
                }
                else {
                    ForEach(filtered) { user in
                        ChatRows(user: user)                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
        }
    }
}
