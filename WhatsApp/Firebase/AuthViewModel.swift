import Foundation
import FirebaseAuth
import SwiftUI

@MainActor @Observable final class AuthViewModel {
    var user: FireUserModel?
    var verificationID = ""
    var otpCode = ""
    var isAuthenticated = false
    var showingError = false
    var errorMessage = ""

    init() {
        loadCurrentUser()
    }

    // MARK: - Load Current User
    private func loadCurrentUser() {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        user = FireUserModel(
            uid: firebaseUser.uid,
            fullName: firebaseUser.displayName ?? "",
            email: firebaseUser.email,
            phoneNumber: firebaseUser.phoneNumber,
            profileImageURL: nil
        )
        print ("\(user.debugDescription)")
        isAuthenticated = true
    }

    // MARK: - Sign Up with Email
    func signUpWithEmail(email: String, password: String, fullName: String, phoneNumber: String ) async {
        guard !email.isEmpty, !password.isEmpty, !fullName.isEmpty ,!phoneNumber.isEmpty else {
            showError("Please fill in all fields")
            return
        }

        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
//            let user = FireUserModel(uid: authResult.user.uid, fullName: fullName, email: email, phoneNumber: phoneNumber , profileImageURL: nil)
            isAuthenticated = true
        } catch {
            showError(error.localizedDescription)
        }
    }


    // MARK: - Sign In with Email
    func signInWithEmail(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            showError("Please enter both email and password")
            return
        }

        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
            isAuthenticated = true
        } catch {
            showError(error.localizedDescription)
        }
    }


    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            user = nil
        } catch {
            showError(error.localizedDescription)
        }
    }

    // MARK: - Update Email
    func updateEmail(newEmail: String) async {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        do {
            try await firebaseUser.updateEmail(to: newEmail)
            user?.email = newEmail
        } catch {
            showError(error.localizedDescription)
        }
    }

    // MARK: - Update Password
    func updatePassword(newPassword: String) async {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        do {
            try await firebaseUser.updatePassword(to: newPassword)
        } catch {
            showError(error.localizedDescription)
        }
    }

    // MARK: - Update Display Name
    func updateDisplayName(newName: String) async {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        let changeRequest = firebaseUser.createProfileChangeRequest()
        changeRequest.displayName = newName
        do {
            try await changeRequest.commitChanges()
            user?.fullName = newName
        } catch {
            showError(error.localizedDescription)
        }
    }

    // MARK: - Delete Account
    func deleteAccount() async {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        do {
            try await firebaseUser.delete()
            isAuthenticated = false
            user = nil
        } catch {
            showError(error.localizedDescription)
        }
    }

    // MARK: - Helper Functions
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}
