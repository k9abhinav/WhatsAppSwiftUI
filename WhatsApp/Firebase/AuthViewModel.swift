import Firebase
import FirebaseAuth
import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import UIKit
import FirebaseFirestore

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

    // MARK : - Load Current User
    private func loadCurrentUser() {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        user = FireUserModel(
            uid: firebaseUser.uid,
            fullName: firebaseUser.displayName ?? "",
            email: firebaseUser.email,
            phoneNumber: firebaseUser.phoneNumber,
            profileImageURL: nil
        )
        print ("This is : \(user.debugDescription)")
        isAuthenticated = true
    }

    // MARK : - Sign Up with Email
    func signUpWithEmail(email: String, password: String, fullName: String, phoneNumber: String ) async {

        guard !email.isEmpty, !password.isEmpty, !fullName.isEmpty ,!phoneNumber.isEmpty else {
            showError("Please fill in all fields")
            return
        }

        do {
//            let authResult =
            try await Auth.auth().createUser(withEmail: email, password: password)
//            let user = FireUserModel(uid: authResult.user.uid, fullName: fullName, email: email, phoneNumber: phoneNumber , profileImageURL: nil)
            isAuthenticated = true
        } catch {
            showError(error.localizedDescription)
        }
    }


    // MARK : - Sign In with Email
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


    // MARK : - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            user = nil
        } catch {
            showError(error.localizedDescription)
        }
    }

    // MARK : - Update Email
    func updateEmail(newEmail: String) async {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        do {
            try await firebaseUser.updateEmail(to: newEmail)
            user?.email = newEmail
        } catch {
            showError(error.localizedDescription)
        }
    }

    // MARK : - Update Password
    func updatePassword(newPassword: String) async {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        do {
            try await firebaseUser.updatePassword(to: newPassword)
        } catch {
            showError(error.localizedDescription)
        }
    }

    // MARK : - Update Display Name
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
    // MARK : SIGN IN WITH GOOGLE
    func signInWithGoogle(presenting viewController: UIViewController) async {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            showError("Missing Firebase Client ID")
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        do {
            let userAuth = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            guard let idToken = userAuth.user.idToken?.tokenString else {
                showError("Failed to retrieve Google ID Token")
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: userAuth.user.accessToken.tokenString)

            let authResult = try await Auth.auth().signIn(with: credential)
            let firebaseUser = authResult.user
            print("DEBUG: Firebase Sign-In successful. UID: \(firebaseUser.uid)")
            let userRef = Firestore.firestore().collection("users").document(firebaseUser.uid)

            // Check if user exists in Firestore
            let document = try await userRef.getDocument()
            if document.exists {
                print("DEBUG: User already exists in Firestore")
            } else {
                print("DEBUG: User does not exist in Firestore. Creating new entry.")

                // Create a new user in Firestore
                let userData: [String: Any] = [
                    "uid": firebaseUser.uid,
                    "fullName": firebaseUser.displayName ?? "",
                    "email": firebaseUser.email ?? "",
                    "phoneNumber": firebaseUser.phoneNumber ?? "",
                    "profileImageURL": firebaseUser.photoURL?.absoluteString ?? "",
                    "createdAt": FieldValue.serverTimestamp()
                ]
                try await userRef.setData(userData)
                print("DEBUG: User successfully created in Firestore")
            }

            // Update local user model
            user = FireUserModel(
                uid: firebaseUser.uid,
                fullName: firebaseUser.displayName ?? "",
                email: firebaseUser.email,
                phoneNumber: firebaseUser.phoneNumber,
                profileImageURL: firebaseUser.photoURL?.absoluteString
            )

            isAuthenticated = true
        } catch {
            print("DEBUG: Error occurred during Google Sign-In - \(error.localizedDescription)")
            showError(error.localizedDescription)
        }
    }

    // MARK: PHONE N OTP as password
    func sendOTP(phoneNumber: String) async {
        guard !phoneNumber.isEmpty else {
            showError("Please enter a valid phone number")
            return
        }

        let formattedPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        guard formattedPhone.hasPrefix("+") else {
            showError("Phone number must include country code (e.g., +1 for the US).")
            return
        }

        do {
            print("Requesting OTP for: \(formattedPhone)")

            let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(formattedPhone, uiDelegate: nil)
            DispatchQueue.main.async {
                self.verificationID = verificationID
                print("OTP sent successfully! Verification ID: \(verificationID)")
            }
        } catch {
            DispatchQueue.main.async {
                self.showError("Failed to send OTP: \(error.localizedDescription)")
                print("Error sending OTP: \(error.localizedDescription)")

                if let error = error as NSError? {
                    print("Debug Info - Code: \(error.code), Domain: \(error.domain)")
                }
            }
        }
    }




    func verifyOTP(otpCode: String) async {
        guard !otpCode.isEmpty, !verificationID.isEmpty else {
            showError("Invalid OTP or missing verification ID")
            return
        }

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: otpCode
        )

        do {
            let authResult = try await Auth.auth().signIn(with: credential)
            let firebaseUser = authResult.user

            user = FireUserModel(
                uid: firebaseUser.uid,
                fullName: firebaseUser.displayName ?? "",
                email: firebaseUser.email,
                phoneNumber: firebaseUser.phoneNumber,
                profileImageURL: nil
            )

            isAuthenticated = true
        } catch {
            showError(error.localizedDescription)
        }
    }


    // MARK : - Delete Account
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

