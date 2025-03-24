import Firebase
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import SwiftUI

@MainActor
@Observable final class AuthViewModel {
    // MARK: - Properties
    var currentLoggedInUser: FireUserModel?
    var verificationID = ""
    var otpCode = ""
    var userIsAuthenticated = false
    var showingError = false
    var errorMessage = ""
    var typeOfAuth: AuthType = .unknown

    // MARK: - Constants
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let usersCollection: CollectionReference
    private let defaultAboutInfo = "Hey there! I am using this app."

    // MARK: - Init
    init() {
        usersCollection = db.collection("users")
        Task {
            await loadCurrentUser()
        }
    }

    // MARK: - Load Current User
    func loadCurrentUser() async {
        guard let firebaseUser = auth.currentUser else {
            print("DEBUG: No authenticated user found.")
            userIsAuthenticated = false
            signOut()
            return
        }

        do {
            try await firebaseUser.reload() // Refresh user session

            if auth.currentUser == nil {
                print("DEBUG: User no longer exists in Firebase Auth.")
                userIsAuthenticated = false
                try auth.signOut()
                return
            }

            let userRef = getUserRef(userId: firebaseUser.uid)
            let document = try await userRef.getDocument()

            if document.exists, let data = document.data() {
                currentLoggedInUser = createUserModel(
                    firebaseUser: firebaseUser,
                    data: data
                )
            } else {
                print("DEBUG: User document not found in Firestore.")
            }

            userIsAuthenticated = true
            print("DEBUG: Loaded user - \(String(describing: currentLoggedInUser))")
        } catch {
            print("DEBUG: Error loading user from Firestore - \(error.localizedDescription)")
        }
    }

    // MARK: - Sign Up with Email
    func signUpWithEmail(email: String, password: String, fullName: String, phoneNumber: String) async {
        guard !email.isEmpty, !password.isEmpty, !fullName.isEmpty, !phoneNumber.isEmpty else {
            showError("Please fill in all fields")
            return
        }

        do {
            // Check if user already exists
            let snapshot = try await getUserByEmail(email)
            if !snapshot.documents.isEmpty {
                showError("User already exists. Please sign in.")
                return
            }

            // Create user in Auth
            let authResult = try await auth.createUser(withEmail: email, password: password)
            let firebaseUser = authResult.user

            // Create user in Firestore
            let userData = createUserData(
                id: firebaseUser.uid,
                phone: phoneNumber,
                name: fullName,
                email: email,
                authType: "email"
            )

            try await getUserRef(userId: firebaseUser.uid).setData(userData)

            // Set current user
            currentLoggedInUser = FireUserModel(
                id: firebaseUser.uid,
                phoneNumber: phoneNumber,
                name: fullName,
                imageUrl: nil,
                aboutInfo: defaultAboutInfo,
                createdDate: Date(),
                email: email,
                typeOfAuth: .email,
                lastSeenTime: nil,
                onlineStatus: false
            )
            userIsAuthenticated = true
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
            // Check if user exists in Firestore
            let snapshot = try await getUserByEmail(email)
            if snapshot.documents.isEmpty {
                showError("No account found with this email. Please sign up.")
                return
            }

            // Sign in with Firebase Auth
            let authResult = try await auth.signIn(withEmail: email, password: password)
            let firebaseUser = authResult.user

            print("DEBUG: Firebase Email Sign-In successful. UID: \(firebaseUser.uid)")

            // Get user data from Firestore
            let document = snapshot.documents.first
            let data = document?.data()

            currentLoggedInUser = FireUserModel(
                id: firebaseUser.uid,
                phoneNumber: data?["phoneNumber"] as? String ?? "",
                name: data?["name"] as? String ?? "",
                imageUrl: data?["imageUrl"] as? String,
                aboutInfo: data?["aboutInfo"] as? String ?? defaultAboutInfo,
                createdDate: (data?["createdDate"] as? Timestamp)?.dateValue(),
                email: email,
                typeOfAuth: .email,
                lastSeenTime: (data?["lastSeenTime"] as? Timestamp)?.dateValue(),
                onlineStatus: data?["onlineStatus"] as? Bool
            )
            userIsAuthenticated = true
        } catch {
            print("DEBUG: Error occurred during Email Sign-In - \(error.localizedDescription)")
            showError(error.localizedDescription)
        }
    }

    // MARK: - Sign Out
    func signOut() {
        do {
            try auth.signOut()
            userIsAuthenticated = false
            currentLoggedInUser = nil
        } catch {
            showError(error.localizedDescription)
        }
    }

    // MARK: - Update User Email
    func updateUserEmail(currentEmail: String, currentPassword: String, newEmail: String, userId: String, completion: @escaping (Error?) -> Void) {
        guard let user = auth.currentUser else {
            completion(NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]))
            return
        }

        let credential = EmailAuthProvider.credential(withEmail: currentEmail, password: currentPassword)

        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                completion(error)
                return
            }

            user.updateEmail(to: newEmail) { error in
                if let error = error {
                    completion(error)
                    return
                }

                self.getUserRef(userId: userId).updateData(["email": newEmail]) { error in
                    completion(error)
                }
            }
        }
    }

    // MARK: - Update Password
    func updatePassword(newPassword: String) async {
        guard let firebaseUser = auth.currentUser else { return }
        do {
            try await firebaseUser.updatePassword(to: newPassword)
        } catch {
            showError(error.localizedDescription)
        }
    }

    func updateUserPassword(currentEmail: String, currentPassword: String, newPassword: String, completion: @escaping (Error?) -> Void) {
        guard let user = auth.currentUser else {
            completion(NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]))
            return
        }

        let credential = EmailAuthProvider.credential(withEmail: currentEmail, password: currentPassword)

        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                completion(error)
                return
            }

            user.updatePassword(to: newPassword) { error in
                completion(error)
            }
        }
    }

    // MARK: - Sign In With Google
    func signInWithGoogle(presenting viewController: UIViewController) async {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            showError("Missing Firebase Client ID")
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        do {
            let googleUser = try await signInWithGoogleHelper(presenting: viewController)
            guard let email = googleUser.user.profile?.email else {
                showError("Failed to retrieve email from Google account")
                return
            }

            // Check if user exists in Firestore
            let snapshot = try await getUserByEmail(email)
            if snapshot.documents.isEmpty {
                showError("No account found with this email. Please sign up.")
                return
            }

            // Sign in with Firebase
            let credential = GoogleAuthProvider.credential(
                withIDToken: googleUser.user.idToken!.tokenString,
                accessToken: googleUser.user.accessToken.tokenString
            )

            let authResult = try await auth.signIn(with: credential)
            let firebaseUser = authResult.user

            print("DEBUG: Firebase Sign-In successful. UID: \(firebaseUser.uid)")

            let document = snapshot.documents.first
            let data = document?.data()

            currentLoggedInUser = FireUserModel(
                id: firebaseUser.uid,
                phoneNumber: data?["phone"] as? String ?? "",
                name: data?["name"] as? String ?? "",
                imageUrl: data?["imageUrl"] as? String,
                aboutInfo: data?["aboutInfo"] as? String ?? defaultAboutInfo,
                email: email,
                typeOfAuth: .google,
                onlineStatus: data?["onlineStatus"] as? Bool ?? nil
            )
            userIsAuthenticated = true
        } catch {
            print("DEBUG: Error occurred during Google Sign-In - \(error.localizedDescription)")
            showError(error.localizedDescription)
        }
    }

    // MARK: - Sign Up With Google
    // MARK: - Sign Up With Google (with account checking and linking flow)
    func signUpWithGoogle(presenting viewController: UIViewController) async {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            showError("Missing Firebase Client ID")
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        do {
            // Get Google sign-in result
            let googleUser = try await signInWithGoogleHelper(presenting: viewController)
            guard let email = googleUser.user.profile?.email else {
                showError("Failed to retrieve email from Google account")
                return
            }

            // Check if user exists in Firestore with this email
            let snapshot = try await getUserByEmail(email)

            if !snapshot.documents.isEmpty {
                // User already exists with this email
                let userDoc = snapshot.documents.first!
                let userData = userDoc.data()
                let authType = userData["authType"] as? String ?? "unknown"

                print("DEBUG: User with email \(email) already exists with auth type: \(authType)")

                if authType == "email" {
                    // Set a flag to indicate account linking is needed
                    // This is the key improvement - automatically notify the user that account linking is available
                    DispatchQueue.main.async {
                        self.typeOfAuth = .email  // Store the existing account type

                        // Store the Google credentials for later linking after email password auth
                        self.pendingGoogleCredential = GoogleAuthProvider.credential(
                            withIDToken: googleUser.user.idToken!.tokenString,
                            accessToken: googleUser.user.accessToken.tokenString
                        )

                        // Show a specific message to guide the user
                        self.showError("We found an existing account with this email. Please enter your password to link your Google account.")

                        // Here you would transition to a special UI for account linking
                        // For example, showing a password entry field for the existing account
                        self.showAccountLinkingPrompt = true
                    }
                    return
                } else if authType == "google" {
                    // Already registered with Google, just sign in
                    await signInWithGoogle(presenting: viewController)
                    return
                }
            }

            // No existing user, proceed with normal Google sign up
            let credential = GoogleAuthProvider.credential(
                withIDToken: googleUser.user.idToken!.tokenString,
                accessToken: googleUser.user.accessToken.tokenString
            )

            let authResult = try await auth.signIn(with: credential)
            let firebaseUser = authResult.user
            let userRef = getUserRef(userId: firebaseUser.uid)

            let fullName = googleUser.user.profile?.name ?? "Unknown User"
            let profileImageURL = googleUser.user.profile?.imageURL(withDimension: 200)?.absoluteString
            let phoneNumber = firebaseUser.phoneNumber ?? ""

            // Create user in Firestore
            let userData = createUserData(
                id: firebaseUser.uid,
                phone: phoneNumber,
                name: fullName,
                imageUrl: profileImageURL,
                email: email,
                authType: "google"
            )

            try await userRef.setData(userData)
            print("DEBUG: New user successfully created in Firestore")

            currentLoggedInUser = FireUserModel(
                id: firebaseUser.uid,
                phoneNumber: phoneNumber,
                name: fullName,
                imageUrl: profileImageURL,
                aboutInfo: defaultAboutInfo,
                email: email,
                typeOfAuth: .google,
                onlineStatus: false
            )
            userIsAuthenticated = true
        } catch {
            print("DEBUG: Error occurred during Google Sign-Up - \(error.localizedDescription)")
            showError(error.localizedDescription)
        }
    }

    // Add these properties to your AuthViewModel
    var pendingGoogleCredential: AuthCredential?
    var showAccountLinkingPrompt = false

    // MARK: - Complete Google Account Linking (after password verification)
    func completeGoogleAccountLinking(email: String, password: String) async {
        guard let pendingCredential = pendingGoogleCredential else {
            showError("No pending Google account to link")
            return
        }

        do {
            // First authenticate with email/password
            let authResult = try await auth.signIn(withEmail: email, password: password)
            let firebaseUser = authResult.user

            // Then link the Google credential
            try await firebaseUser.link(with: pendingCredential)

            // Update user data in Firestore
            try await getUserRef(userId: firebaseUser.uid).updateData([
                "typeOfAuth": "linkedWithGoogle",
                "linkedProviders": FieldValue.arrayUnion(["google"])


            ])

            // Refresh user data
            await loadCurrentUser()

            // Reset the pending credential
            pendingGoogleCredential = nil
            showAccountLinkingPrompt = false

            print("DEBUG: Successfully linked Google account")
            // Show success message
        } catch {
            print("DEBUG: Error during account linking: \(error.localizedDescription)")
            showError("Failed to link accounts: \(error.localizedDescription)")
        }
    }

    // MARK: - Send OTP
    func sendOTP(phoneNumber: String) async {
        do {
            Auth.auth().settings?.isAppVerificationDisabledForTesting = false

            let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber("+911234567890", uiDelegate: nil)
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

    // MARK: - Delete Account
    func deleteAccountandUser() async {
        guard let firebaseUser = auth.currentUser else { return }

        let userRef = getUserRef(userId: firebaseUser.uid)

        do {
            print("DEBUG: Deleting user document from Firestore for UID: \(String(describing: firebaseUser.displayName))")
            try await userRef.delete()
            print("DEBUG: User document successfully deleted from Firestore")
            try await firebaseUser.delete()
            print("DEBUG: User successfully deleted from Firebase Authentication")
            signOut()
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

    private func getUserRef(userId: String) -> DocumentReference {
        return usersCollection.document(userId)
    }

    private func getUserByEmail(_ email: String) async throws -> QuerySnapshot {
        return try await usersCollection.whereField("email", isEqualTo: email).getDocuments()
    }

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

    private func createUserModel(firebaseUser: FirebaseAuth.User, data: [String: Any]) -> FireUserModel {
        return FireUserModel(
            id: firebaseUser.uid,
            phoneNumber: data["phoneNumber"] as? String ?? "",
            name: data["name"] as? String ?? firebaseUser.displayName ?? "",
            imageUrl: data["imageUrl"] as? String,
            aboutInfo: data["aboutInfo"] as? String ?? defaultAboutInfo,
            createdDate: (data["createdDate"] as? Timestamp)?.dateValue(),
            email: firebaseUser.email,
            typeOfAuth: getAuthType(for: firebaseUser),
            lastSeenTime: (data["lastSeenTime"] as? Timestamp)?.dateValue(),
            onlineStatus: data["onlineStatus"] as? Bool
        )
    }

    private func createUserData(
        id: String,
        phone: String,
        name: String,
        imageUrl: String? = nil,
        email: String,
        authType: String,
        onlineStatus: Bool? = nil
    ) -> [String: Any] {
        return [
            "id": id,
            "phoneNumber": phone,
            "name": name,
            "imageUrl": imageUrl ?? "",
            "aboutInfo": defaultAboutInfo,
            "createdDate": Timestamp(date: Date()),
            "email": email,
            "authType": authType,
            "lastSeenTime": Date() ,
            "onlineStatus": false
        ]
    }

    private func signInWithGoogleHelper(presenting viewController: UIViewController) async throws -> GIDSignInResult {
        let userAuth = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        guard (userAuth.user.idToken?.tokenString) != nil else {
            throw NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve Google ID Token"])
        }
        return userAuth
    }
}
