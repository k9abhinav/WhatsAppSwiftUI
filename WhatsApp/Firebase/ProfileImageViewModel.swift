//
//  ProfileImageViewModel.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 11/03/25.
//

import SwiftUI
import FirebaseAuth

@Observable class ProfileImageViewModel {
    var userImageData: Data?
    var profileImageURL: String?

    init() {
        fetchCurrentUserProfileImageURL()
        loadImage()
    }

    func fetchCurrentUserProfileImageURL() {
        guard let user = Auth.auth().currentUser, let photoURL = user.photoURL else {
            return
        }
        self.profileImageURL = photoURL.absoluteString
    }

    func loadImage() {
        guard let profileImageURL = profileImageURL, let url = URL(string: profileImageURL) else {
            return
        }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                await MainActor.run {
                    self.userImageData = data
                }
            } catch {
                print("Error loading image: \(error)")
            }
        }
    }
}
