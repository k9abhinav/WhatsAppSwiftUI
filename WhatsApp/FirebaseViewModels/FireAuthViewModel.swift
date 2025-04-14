import Firebase
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import SwiftUI

@MainActor
@Observable final class FireAuthViewModel {
    // MARK: - Properties
    var currentLoggedInUser: FireUserModel?
    var verificationID = ""
    var otpCode = ""
    var userIsAuthenticated = false
    var showingError = false
    var errorMessage = ""
    var typeOfAuth: AuthType = .unknown
    var pendingGoogleCredential: AuthCredential?
    var showAccountLinkingPrompt = false

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
    // MARK: - Load Current User (updated with session validation)
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
                // Check if this device's session is still valid
                let storedSessionId = data["currentSessionId"] as? String
                let deviceSessionId = UserDefaults.standard.string(forKey: "userSessionId_\(firebaseUser.uid)")

                if let storedSessionId = storedSessionId,
                   let deviceSessionId = deviceSessionId,
                   storedSessionId != deviceSessionId {
                    // This device has been logged out by another login
                    print("DEBUG: Session invalid - user was logged in elsewhere")
                    userIsAuthenticated = false
                    try auth.signOut()
                    showError("Your account was logged in on another device.")
                    return
                }

                // Create user model with session information
                var userModel = createUserModel(
                    firebaseUser: firebaseUser,
                    data: data
                )

                // If no session exists, create one
                if storedSessionId == nil {
                    let newSessionId = generateSessionId()
                    try await userRef.updateData([
                        "currentSessionId": newSessionId,
                        "lastLoginTime": Timestamp(date: Date()),
                        "lastDevice": UIDevice.current.name
                    ])

                    // Save session locally
                    UserDefaults.standard.set(newSessionId, forKey: "userSessionId_\(firebaseUser.uid)")

                    // Update user model
                    userModel.currentSessionId = newSessionId
                } else {
                    // Save existing session locally
                    UserDefaults.standard.set(storedSessionId, forKey: "userSessionId_\(firebaseUser.uid)")
                    userModel.currentSessionId = storedSessionId
                }

                currentLoggedInUser = userModel
            } else {
                print("DEBUG: User document not found in Firestore.")
            }

            userIsAuthenticated = true
            print("DEBUG: Loaded current user - \(String(describing: currentLoggedInUser?.name))")

            // Start monitoring for session changes
            monitorSessionStatus()
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
            let snapshot = try await getUserByEmail(email)
            if !snapshot.documents.isEmpty {
                showError("User already exists. Please sign in.")
                return
            }

            let authResult = try await auth.createUser(withEmail: email, password: password)
            let firebaseUser = authResult.user

            let userData = createUserData(
                id: firebaseUser.uid,
                phone: phoneNumber,
                name: fullName,
                email: email,
                authType: "email"
            )
            try await getUserRef(userId: firebaseUser.uid).setData(userData)

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

    // MARK: - Sign In with Email (SESSION MANAGEMENT)
    //    func signInWithEmail(email: String, password: String) async {
    //        guard !email.isEmpty, !password.isEmpty else {
    //            showError("Please enter both email and password")
    //            return
    //        }
    //
    //        do {
    //            let snapshot = try await getUserByEmail(email)
    //            if snapshot.documents.isEmpty {
    //                showError("No account found with this email. Please sign up.")
    //                return
    //            }
    //            // Check if user is already logged in elsewhere
    //            if let userId = snapshot.documents.first?.documentID {
    //                let (isActive, _) = await checkActiveSession(userId: userId)
    //
    //                if isActive {
    //                    // Option 1: Prevent login and inform user
    //                    // showError("This account is already logged in on another device. Please log out there first.")
    //                    // return
    //
    //                    // Option 2: Force logout on other device and continue
    //                    print("DEBUG: User already logged in elsewhere, forcing logout on other device")
    //                }
    //            }
    //            let authResult = try await auth.signIn(withEmail: email, password: password)
    //            let firebaseUser = authResult.user
    //
    //            print("DEBUG: Firebase Email Sign-In successful. UID: \(firebaseUser.uid)")
    //            let sessionId = await updateUserSession(userId: firebaseUser.uid)
    //            let document = snapshot.documents.first
    //            let data = document?.data()
    //
    //            currentLoggedInUser = FireUserModel(
    //                id: firebaseUser.uid,
    //                phoneNumber: data?["phoneNumber"] as? String ?? "",
    //                name: data?["name"] as? String ?? "",
    //                imageUrl: data?["imageUrl"] as? String,
    //                aboutInfo: data?["aboutInfo"] as? String ?? defaultAboutInfo,
    //                createdDate: (data?["createdDate"] as? Timestamp)?.dateValue(),
    //                email: email,
    //                typeOfAuth: .email,
    //                lastSeenTime: (data?["lastSeenTime"] as? Timestamp)?.dateValue(),
    //                onlineStatus: data?["onlineStatus"] as? Bool,
    //                currentSessionId: sessionId
    //            )
    //            userIsAuthenticated = true
    //        } catch {
    //            print("DEBUG: Error occurred during Email Sign-In - \(error.localizedDescription)")
    //            showError(error.localizedDescription)
    //        }
    //    }

    // MARK: - Sign Out (WITH SESSION MANAGAMENT)
    //    func signOut() {
    //        do {
    //            // Clear the session ID when logging out
    //            if let userId = currentLoggedInUser?.id {
    //                Task {
    //                    do {
    //                        try await getUserRef(userId: userId).updateData([
    //                            "currentSessionId": FieldValue.delete()
    //                        ])
    //                        print("DEBUG: Cleared session ID for user \(userId)")
    //                    } catch {
    //                        print("DEBUG: Failed to clear session: \(error.localizedDescription)")
    //                    }
    //                }
    //            }
    //
    //            try auth.signOut()
    //            userIsAuthenticated = false
    //            currentLoggedInUser = nil
    //        } catch {
    //            showError(error.localizedDescription)
    //        }
    //    }

    // MARK: - Sign In with Email
    func signInWithEmail(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            showError("Please enter both email and password")
            return
        }

        do {
            let snapshot = try await getUserByEmail(email)
            if snapshot.documents.isEmpty {
                showError("No account found with this email. Please sign up.")
                return
            }

            let authResult = try await auth.signIn(withEmail: email, password: password)
            let firebaseUser = authResult.user

            print("DEBUG: Firebase Email Sign-In successful. UID: \(firebaseUser.uid)")

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
    // MARK: CREATE SESSION ID
    private func generateSessionId() -> String {
        return UUID().uuidString
    }

    // Update the user's session information
    private func updateUserSession(userId: String) async -> String {
        let sessionId = generateSessionId()

        do {
            try await getUserRef(userId: userId).updateData([
                "currentSessionId": sessionId,
                "lastLoginTime": Timestamp(date: Date()),
                "lastDevice": UIDevice.current.name // Optional: track which device they're using
            ])
            print("DEBUG: Updated session ID to \(sessionId) for user \(userId)")
            return sessionId
        } catch {
            print("DEBUG: Failed to update session: \(error.localizedDescription)")
            return sessionId // Still return the session ID even if update fails
        }
    }

    // Check if user has an active session elsewhere
    private func checkActiveSession(userId: String) async -> (isActive: Bool, sessionId: String?) {
        do {
            let document = try await getUserRef(userId: userId).getDocument()
            guard let data = document.data(),
                  let sessionId = data["currentSessionId"] as? String else {
                return (false, nil)
            }

            // If session exists, check if it's recent (optional: you can add timeout logic)
            if let lastLoginTime = (data["lastLoginTime"] as? Timestamp)?.dateValue() {
                // For example, consider sessions older than 30 minutes as expired
                if Date().timeIntervalSince(lastLoginTime) > 1800 {
                    return (false, sessionId)
                }
            }

            return (true, sessionId)
        } catch {
            print("DEBUG: Error checking active session: \(error.localizedDescription)")
            return (false, nil)
        }
    }

    // Monitor session status to detect force logouts
    func monitorSessionStatus() {
        guard let userId = currentLoggedInUser?.id else { return }

        // Create a listener for changes to the user document
        let listener = getUserRef(userId: userId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self = self,
                      let document = documentSnapshot,
                      let data = document.data(),
                      let currentSessionId = data["currentSessionId"] as? String,
                      let mySessionId = self.currentLoggedInUser?.currentSessionId else {
                    return
                }

                // If the session IDs don't match, this user has been logged in elsewhere
                if currentSessionId != mySessionId {
                    print("DEBUG: Session invalidated - user logged in elsewhere")
                    self.forceLogout()
                }
            }

        // Store the listener somewhere so it can be removed later (on logout)
        // For example: sessionListener = listener
    }

    // Force logout when another device logs in
    func forceLogout() {
        // Display alert to user
        errorMessage = "You have been logged out because your account was accessed on another device."
        showingError = true

        // Perform logout
        signOut()
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

    // MARK: - Sign In With Google (With session management)
    //    func signInWithGoogle(presenting viewController: UIViewController) async {
    //        guard let clientID = FirebaseApp.app()?.options.clientID else {
    //            showError("Missing Firebase Client ID")
    //            return
    //        }
    //
    //        let config = GIDConfiguration(clientID: clientID)
    //        GIDSignIn.sharedInstance.configuration = config
    //
    //        do {
    //            let googleUser = try await signInWithGoogleHelper(presenting: viewController)
    //            guard let email = googleUser.user.profile?.email else {
    //                showError("Failed to retrieve email from Google account")
    //                return
    //            }
    //
    //            let snapshot = try await getUserByEmail(email)
    //            if snapshot.documents.isEmpty {
    //                showError("No account found with this email. Please sign up.")
    //                return
    //            }
    //
    //            // Check if user is already logged in elsewhere
    //            if let userId = snapshot.documents.first?.documentID {
    //                let (isActive, _) = await checkActiveSession(userId: userId)
    //
    //                if isActive {
    //                    // Option 1: Prevent login and inform user
    //                    // showError("This account is already logged in on another device. Please log out there first.")
    //                    // return
    //
    //                    // Option 2: Force logout on other device and continue
    //                    print("DEBUG: User already logged in elsewhere, forcing logout on other device")
    //                }
    //            }
    //
    //            let credential = GoogleAuthProvider.credential(
    //                withIDToken: googleUser.user.idToken!.tokenString,
    //                accessToken: googleUser.user.accessToken.tokenString
    //            )
    //
    //            let authResult = try await auth.signIn(with: credential)
    //            let firebaseUser = authResult.user
    //
    //            print("DEBUG: Firebase Google Sign-In successful. UID: \(firebaseUser.uid)")
    //
    //            // Generate and save new session ID
    //            let sessionId = await updateUserSession(userId: firebaseUser.uid)
    //
    //            let document = snapshot.documents.first
    //            let data = document?.data()
    //
    //            currentLoggedInUser = FireUserModel(
    //                id: firebaseUser.uid,
    //                phoneNumber: data?["phone"] as? String ?? "",
    //                name: data?["name"] as? String ?? "",
    //                imageUrl: data?["imageUrl"] as? String,
    //                aboutInfo: data?["aboutInfo"] as? String ?? defaultAboutInfo,
    //                email: email,
    //                typeOfAuth: .google,
    //                onlineStatus: data?["onlineStatus"] as? Bool ?? nil,
    //                currentSessionId: sessionId // Add the session ID here
    //            )
    //            userIsAuthenticated = true
    //
    //            // Start monitoring for session changes
    //            monitorSessionStatus()
    //        } catch {
    //            print("DEBUG: Error occurred during Google Sign-In - \(error.localizedDescription)")
    //            showError(error.localizedDescription)
    //        }
    //    }
    // MARK: - Sign In With Google
    // MARK: SIGN IN GOOGLE
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

            let snapshot = try await getUserByEmail(email)
            if snapshot.documents.isEmpty {
                showError("No account found with this email. Please sign up.")
                return
            }

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

    // MARK: - Complete Google Account Linking (updated with session management)
    func completeGoogleAccountLinking(email: String, password: String) async {
        guard let pendingCredential = pendingGoogleCredential else {
            showError("No pending Google account to link")
            return
        }

        do {
            // First check if user is logged in elsewhere
            let snapshot = try await getUserByEmail(email)
            if let document = snapshot.documents.first {
                let userId = document.documentID
                let (isActive, _) = await checkActiveSession(userId: userId)

                if isActive {
                    // Option 1: Prevent login and inform user
                    // showError("This account is already logged in on another device. Please log out there first.")
                    // return

                    // Option 2: Force logout on other device and continue
                    print("DEBUG: User already logged in elsewhere, forcing logout on other device")
                }
            }

            let authResult = try await auth.signIn(withEmail: email, password: password)
            let firebaseUser = authResult.user

            try await firebaseUser.link(with: pendingCredential)

            // Generate and save new session ID
            let sessionId = await updateUserSession(userId: firebaseUser.uid)

            try await getUserRef(userId: firebaseUser.uid).updateData([
                "typeOfAuth": "linkedWithGoogle",
                "linkedProviders": FieldValue.arrayUnion(["google"]),
                "currentSessionId": sessionId,
                "lastDevice": UIDevice.current.name
            ])

            await loadCurrentUser()

            // Update the currentSessionId in the user model
            if currentLoggedInUser != nil {
                var updatedUser = currentLoggedInUser!
                updatedUser.currentSessionId = sessionId
                currentLoggedInUser = updatedUser
            }

            pendingGoogleCredential = nil
            showAccountLinkingPrompt = false

            print("DEBUG: Successfully linked Google account with session ID: \(sessionId)")

            // Start monitoring for session changes
            monitorSessionStatus()
        } catch {
            print("DEBUG: Error during account linking: \(error.localizedDescription)")
            showError("Failed to link accounts: \(error.localizedDescription)")
        }
    }
    // MARK: - Sign Up With Google (updated with session management)
//    func signUpWithGoogle(presenting viewController: UIViewController) async {
//        guard let clientID = FirebaseApp.app()?.options.clientID else {
//            showError("Missing Firebase Client ID")
//            return
//        }
//
//        let config = GIDConfiguration(clientID: clientID)
//        GIDSignIn.sharedInstance.configuration = config
//
//        do {
//            let googleUser = try await signInWithGoogleHelper(presenting: viewController)
//            guard let email = googleUser.user.profile?.email else {
//                showError("Failed to retrieve email from Google account")
//                return
//            }
//
//            let snapshot = try await getUserByEmail(email)
//
//            if !snapshot.documents.isEmpty {
//                let userDoc = snapshot.documents.first!
//                let userData = userDoc.data()
//                let authType = userData["authType"] as? String ?? "unknown"
//
//                print("DEBUG: User with email \(email) already exists with auth type: \(authType)")
//
//                // Check if user is already logged in elsewhere
//                let (isActive, _) = await checkActiveSession(userId: userDoc.documentID)
//
//                if isActive {
//                    // Option 1: Prevent login and inform user
//                    // showError("This account is already logged in on another device. Please log out there first.")
//                    // return
//
//                    // Option 2: Force logout on other device and continue
//                    print("DEBUG: User already logged in elsewhere, forcing logout on other device")
//                }
//
//                if authType == "email" {
//                    DispatchQueue.main.async {
//                        self.typeOfAuth = .email
//
//                        self.pendingGoogleCredential = GoogleAuthProvider.credential(
//                            withIDToken: googleUser.user.idToken!.tokenString,
//                            accessToken: googleUser.user.accessToken.tokenString
//                        )
//
//                        self.showError("We found an existing account with this email. Please enter your password to link your Google account.")
//
//                        self.showAccountLinkingPrompt = true
//                    }
//                    return
//                } else if authType == "google" {
//                    await signInWithGoogle(presenting: viewController)
//                    return
//                }
//            }
//
//            let credential = GoogleAuthProvider.credential(
//                withIDToken: googleUser.user.idToken!.tokenString,
//                accessToken: googleUser.user.accessToken.tokenString
//            )
//
//            let authResult = try await auth.signIn(with: credential)
//            let firebaseUser = authResult.user
//            let userRef = getUserRef(userId: firebaseUser.uid)
//
//            let fullName = googleUser.user.profile?.name ?? "Unknown User"
//            let profileImageURL = googleUser.user.profile?.imageURL(withDimension: 200)?.absoluteString
//            let phoneNumber = firebaseUser.phoneNumber ?? ""
//
//            // Generate a session ID for this new user
//            let sessionId = generateSessionId()
//
//            // Add sessionId to user data
//            var userData = createUserData(
//                id: firebaseUser.uid,
//                phone: phoneNumber,
//                name: fullName,
//                imageUrl: profileImageURL,
//                email: email,
//                authType: "google"
//            )
//            userData["currentSessionId"] = sessionId
//            userData["lastDevice"] = UIDevice.current.name
//
//            try await userRef.setData(userData)
//            print("DEBUG: New user successfully created in Firestore with session ID: \(sessionId)")
//
//            currentLoggedInUser = FireUserModel(
//                id: firebaseUser.uid,
//                phoneNumber: phoneNumber,
//                name: fullName,
//                imageUrl: profileImageURL,
//                aboutInfo: defaultAboutInfo,
//                email: email,
//                typeOfAuth: .google,
//                onlineStatus: false,
//                currentSessionId: sessionId
//            )
//            userIsAuthenticated = true
//
//            // Start monitoring for session changes
//            monitorSessionStatus()
//        } catch {
//            print("DEBUG: Error occurred during Google Sign-Up - \(error.localizedDescription)")
//            showError(error.localizedDescription)
//        }
//    }

    // MARK: - Sign Up With Google (with account checking and linking flow)
        func signUpWithGoogle(presenting viewController: UIViewController) async {
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

                let snapshot = try await getUserByEmail(email)

                if !snapshot.documents.isEmpty {

                    let userDoc = snapshot.documents.first!
                    let userData = userDoc.data()
                    let authType = userData["authType"] as? String ?? "unknown"

                    print("DEBUG: User with email \(email) already exists with auth type: \(authType)")

                    if authType == "email" {

                        DispatchQueue.main.async {
                            self.typeOfAuth = .email

                            self.pendingGoogleCredential = GoogleAuthProvider.credential(
                                withIDToken: googleUser.user.idToken!.tokenString,
                                accessToken: googleUser.user.accessToken.tokenString
                            )

                            self.showError("We found an existing account with this email. Please enter your password to link your Google account.")

                            self.showAccountLinkingPrompt = true
                        }
                        return
                    } else if authType == "google" {
                        await signInWithGoogle(presenting: viewController)
                        return
                    }
                }

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
            onlineStatus: data["onlineStatus"] as? Bool,
            isTyping: data["isTyping"] as? Bool
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
         [
            "id": id,
            "phoneNumber": phone,
            "name": name,
            "imageUrl": imageUrl ?? "",
            "aboutInfo": defaultAboutInfo,
            "createdDate": Timestamp(date: Date()),
            "email": email,
            "authType": authType,
            "lastSeenTime": Date() ,
            "onlineStatus": false,
            "isTyping": false
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
