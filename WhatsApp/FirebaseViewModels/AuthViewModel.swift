import Firebase
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import SwiftUI

@MainActor
@Observable final class AuthViewModel {
    var fireuser : FireUserModel?
    var verificationID = ""
    var otpCode = ""
    var isAuthenticated = false
    var showingError = false
    var errorMessage = ""
    var authType: AuthType = .unknown

    init() {
        Task{
            await loadCurrentUser()
        }
    }

    // MARK: - Load Current User
    private func loadCurrentUser() async {
        guard let firebaseUser = Auth.auth().currentUser else {
            print("DEBUG: No authenticated user found.")
            isAuthenticated = false
            return
        }

        do {
            try await firebaseUser.reload() // Refresh user session

            if Auth.auth().currentUser == nil {
                print("DEBUG: User no longer exists in Firebase Auth.")
                isAuthenticated = false
                try Auth.auth().signOut()
                return
            }

            let userRef = Firestore.firestore().collection("users").document(firebaseUser.uid)
            let document = try await userRef.getDocument()

            if document.exists, let data = document.data() {
                fireuser = FireUserModel(
                    id: firebaseUser.uid,
                    phone: data["phone"] as? String ?? "",
                    name: data["name"] as? String ?? firebaseUser.displayName ?? "",
                    imageUrl: data["imageUrl"] as? String,
                    lastSeen: (data["lastSeen"] as? Timestamp)?.dateValue(),
                    password: nil,  // Do not store password locally
                    aboutInfo: data["aboutInfo"] as? String ?? "Hey there! I am using this app.",
                    email: firebaseUser.email,
                    authType: getAuthType(for: firebaseUser)
                )
            } else {
                print("DEBUG: User document not found in Firestore.")
            }

            isAuthenticated = true
            print("DEBUG: Loaded user - \(String(describing: fireuser))")
        } catch {
            print("DEBUG: Error loading user from Firestore - \(error.localizedDescription)")
//            showError("Failed to load user data.")
        }
    }

    // Helper function to determine auth type
    private func getAuthType(for firebaseUser: FirebaseAuth.User) -> AuthType {
        if let providerID = firebaseUser.providerData.first?.providerID {
            switch providerID {
            case "password": return .email
            case "google.com": return .google
            case "phone": return .phone
            default: return .unknown
            }
        }
        return .unknown
    }


    // MARK: - Sign Up with Email
    func signUpWithEmail(email: String, password: String, fullName: String, phoneNumber: String) async {
        guard !email.isEmpty, !password.isEmpty, !fullName.isEmpty, !phoneNumber.isEmpty else {
            showError("Please fill in all fields")
            return
        }

        let userRef = Firestore.firestore().collection("users").whereField("email", isEqualTo: email)

        do {
            let snapshot = try await userRef.getDocuments()
            if !snapshot.documents.isEmpty {
                showError("User already exists. Please sign in.")
                return
            }

            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            let firebaseUser = authResult.user

            let userData: [String: Any] = [
                "id": firebaseUser.uid,
                "phone": phoneNumber,
                "name": fullName,
                "imageUrl": "",
                "lastSeen": FieldValue.serverTimestamp(),
                "password": password,
                "aboutInfo": "Hey there! I am using this app.",
                "email": email,
                "authType": "email"
            ]
            try await Firestore.firestore().collection("users").document(firebaseUser.uid).setData(userData)

            // Update local user model
            fireuser = FireUserModel(
                id: firebaseUser.uid,
                phone: phoneNumber,
                name: fullName,
                imageUrl: nil,
                lastSeen: nil,
                password: password,
                aboutInfo: "Hey there! I am using this app.",
                email: email,
                authType: .email
            )

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

        let userRef = Firestore.firestore().collection("users")
        let query = userRef.whereField("email", isEqualTo: email)

        do {
            let snapshot = try await query.getDocuments()

            if snapshot.documents.isEmpty {
                showError("No account found with this email. Please sign up.")
                return
            }

            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            let firebaseUser = authResult.user

            print("DEBUG: Firebase Email Sign-In successful. UID: \(firebaseUser.uid)")

            let document = snapshot.documents.first
            let data = document?.data()

            fireuser = FireUserModel(
                id: firebaseUser.uid,
                phone: data?["phone"] as? String ?? "",
                name: data?["name"] as? String ?? "",
                imageUrl: data?["imageUrl"] as? String,
                lastSeen: (data?["lastSeen"] as? Timestamp)?.dateValue(),
                password: nil,  // Password shouldn't be stored locally
                aboutInfo: data?["aboutInfo"] as? String ?? "Hey there! I am using this app.",
                email: email,
                authType: .email
            )

            isAuthenticated = true
        } catch {
            print("DEBUG: Error occurred during Email Sign-In - \(error.localizedDescription)")
            showError(error.localizedDescription)
        }
    }



    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            fireuser = nil
        } catch {
            showError(error.localizedDescription)
        }
    }

    // MARK: - Update Email
    //    func updateEmail(newEmail: String) async {
    //        guard let firebaseUser = Auth.auth().currentUser else { return }
    //        do {
    //            try await firebaseUser.updateEmail(to: newEmail)
    //            user?.email = newEmail
    //        } catch {
    //            showError(error.localizedDescription)
    //        }
    //    }
    func updateUserEmail(currentEmail: String, currentPassword: String, newEmail: String, userId: String, completion: @escaping (Error?) -> Void) {
        let user = Auth.auth().currentUser
        let credential = EmailAuthProvider.credential(withEmail: currentEmail, password: currentPassword)

        user?.reauthenticate(with: credential) { _, error in
            if let error = error {
                completion(error)
                return
            }

            user?.updateEmail(to: newEmail) { error in
                if let error = error {
                    completion(error)
                    return
                }

                let db = Firestore.firestore()
                db.collection("users").document(userId).updateData(["email": newEmail]) { error in
                    completion(error)
                }
            }
        }
    }

    // MARK: - Update Password
    //    func updatePassword(newPassword: String) async {
    //        guard let firebaseUser = Auth.auth().currentUser else { return }
    //        do {
    //            try await firebaseUser.updatePassword(to: newPassword)
    //        } catch {
    //            showError(error.localizedDescription)
    //        }
    //    }

    func updateUserPassword(currentEmail: String, currentPassword: String, newPassword: String, completion: @escaping (Error?) -> Void) {
        let user = Auth.auth().currentUser
        let credential = EmailAuthProvider.credential(withEmail: currentEmail, password: currentPassword)

        user?.reauthenticate(with: credential) { _, error in
            if let error = error {
                completion(error)
                return
            }

            user?.updatePassword(to: newPassword) { error in
                completion(error)
            }
        }
    }


    // MARK: SIGN IN WITH GOOGLE
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

            // Fetch user email
            guard let email = userAuth.user.profile?.email else {
                showError("Failed to retrieve email from Google account")
                return
            }

            let userRef = Firestore.firestore().collection("users")
            let query = userRef.whereField("email", isEqualTo: email)

            let snapshot = try await query.getDocuments()

            if snapshot.documents.isEmpty {
                showError("No account found with this email. Please sign up.")
                return
            }

            // User exists in Firestore, proceed with Firebase Auth sign-in
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: userAuth.user.accessToken.tokenString
            )

            let authResult = try await Auth.auth().signIn(with: credential)
            let firebaseUser = authResult.user

            print("DEBUG: Firebase Sign-In successful. UID: \(firebaseUser.uid)")

            // Fetch user data from Firestore
            let document = snapshot.documents.first
            let data = document?.data()

            // Update local user model using `FireUserModel`
            fireuser = FireUserModel(
                id: firebaseUser.uid,
                phone: data?["phone"] as? String ?? "",
                name: data?["name"] as? String ?? "",
                imageUrl: data?["imageUrl"] as? String,
                lastSeen: (data?["lastSeen"] as? Timestamp)?.dateValue(),
                password: nil,  // Google sign-in doesn't require a password
                aboutInfo: data?["aboutInfo"] as? String ?? "Hey there! I am using this app.",
                email: email,
                authType: .google
            )

            isAuthenticated = true
        } catch {
            print("DEBUG: Error occurred during Google Sign-In - \(error.localizedDescription)")
            showError(error.localizedDescription)
        }
    }


    // MARK: PHONE N OTP as password
    func sendOTP(phoneNumber: String) async {
        //        guard !phoneNumber.isEmpty else {
        //            showError("Please enter a valid phone number")
        //            return
        //        }

        //        let formattedPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        //
        //        guard formattedPhone.hasPrefix("+") else {
        //            showError("Phone number must include country code (e.g., +1 for the US).")
        //            return
        //        }

        do {
            //            print("Requesting OTP for: \(formattedPhone)")

            // Explicitly enable reCAPTCHA verification
            Auth.auth().settings?.isAppVerificationDisabledForTesting = false

            let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber("+911234567890", uiDelegate: nil )
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





    //    func verifyOTP(otpCode: String) async {
    //        guard !otpCode.isEmpty, !verificationID.isEmpty else {
    //            showError("Invalid OTP or missing verification ID")
    //            return
    //        }
    //
    //        let credential = PhoneAuthProvider.provider().credential(
    //            withVerificationID: verificationID,
    //            verificationCode: otpCode
    //        )
    //
    //        do {
    //            let authResult = try await Auth.auth().signIn(with: credential)
    //            let firebaseUser = authResult.user
    //
    //            user = FirebaseUserModel(
    //                uid: firebaseUser.uid,
    //                fullName: firebaseUser.displayName ?? "",
    //                email: firebaseUser.email,
    //                phoneNumber: firebaseUser.phoneNumber,
    //                profileImageURL: nil
    //            )
    //
    //            isAuthenticated = true
    //        } catch {
    //            showError(error.localizedDescription)
    //        }
    //    }


    // MARK: - Delete Account
    func deleteAccountandUser() async {
        guard let firebaseUser = Auth.auth().currentUser else { return  }

        let userRef = Firestore.firestore().collection("users").document(firebaseUser.uid)

        do {
            print("DEBUG: Deleting user document from Firestore for UID: \(String(describing: firebaseUser.displayName))")
            try await userRef.delete()
            print("DEBUG: User document successfully deleted from Firestore")
            try await firebaseUser.delete()
            print("DEBUG: User successfully deleted from Firebase Authentication")
            isAuthenticated = false
            fireuser = nil
        } catch {
            showError(error.localizedDescription)
            print("DEBUG: Error deleting user - \(error.localizedDescription)")
        }
    }





    // MARK: - Helper Functions
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

extension AuthViewModel{
//    MARK: SIGN UP GOOGLE
    func signUppWithGoogle(presenting viewController: UIViewController) async {
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

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: userAuth.user.accessToken.tokenString
            )

            let authResult = try await Auth.auth().signIn(with: credential)
            let firebaseUser = authResult.user
            let userRef = Firestore.firestore().collection("users").document(firebaseUser.uid)

            let fullName = userAuth.user.profile?.name ?? "Unknown User"
            let email = userAuth.user.profile?.email
            let profileImageURL = userAuth.user.profile?.imageURL(withDimension: 200)?.absoluteString
            let phoneNumber = firebaseUser.phoneNumber ?? ""

            let document = try await userRef.getDocument()
            if document.exists {
                print("DEBUG: User already exists in Firestore")
            } else {
                print("DEBUG: Creating new user in Firestore")

                let userData: [String: Any] = [
                    "id": firebaseUser.uid,
                    "phone": phoneNumber,
                    "name": fullName,
                    "imageUrl": profileImageURL ?? "",
                    "lastSeen": FieldValue.serverTimestamp(),
                    "password": "",  // No password needed for Google sign-in
                    "aboutInfo": "Hey there! I am using this app.",
                    "email": email ?? "",
                    "authType": "google"
                ]
                try await userRef.setData(userData)
                print("DEBUG: User successfully created in Firestore")
            }

            fireuser = FireUserModel(
                id: firebaseUser.uid,
                phone: phoneNumber,
                name: fullName,
                imageUrl: profileImageURL,
                lastSeen: nil,
                password: nil,
                aboutInfo: "Hey there! I am using this app.",
                email: email,
                authType: .google
            )

            isAuthenticated = true
        } catch {
            print("DEBUG: Error occurred during Google Sign-In - \(error.localizedDescription)")
            showError(error.localizedDescription)
        }
    }

}



