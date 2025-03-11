
import SwiftUI
import FirebaseAuth
import GoogleSignInSwift

struct SignUpView: View {

    @Environment(AuthViewModel.self) private var viewModel
    @State private var isShowingSignIn = false
    @State private var isLoading = false
    @State private var enteredEmail: String = ""
    @State private var enteredPassword: String = ""
    @State private var enteredFullName: String = ""
    @State private var phoneNumber: String = ""
    @State private var otpCode = ""
    @State private var isOTPOverlayVisible = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    // Header
                    VStack(spacing: 20) {
                        Image("image")
                            .resizable()
                            .scaledToFit()
//                            .aspectRatio(contentMode: .fit)
                            .frame(width: 90, height: 90)
//                            .foregroundColor(.customGreen)

                        Text("Verify Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Enter your Phone Number to get started with WhatsApp Clone.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 50)

                    // Form Fields
                    VStack(spacing: 20) {
                        //                        TextField("Full Name", text: $enteredFullName)
                        //                        .modifier(TextFieldStyle())
                        //                        .autocapitalization(.words)

                        TextField("Phone Number", text: $phoneNumber)
                            .modifier(TextFieldStyle())
                            .keyboardType(.phonePad)


                        //                        TextField("Email", text: $enteredEmail)
                        //                        .modifier(TextFieldStyle())
                        //                        .keyboardType(.emailAddress)
                        //                        .autocapitalization(.none)
                        //
                        //                        SecureField("Password", text: $enteredPassword)
                        //                            .modifier(TextFieldStyle())
                    }
                    .padding(.vertical, 30)

                    // Sign Up Button
                    Button(action: {
                        isLoading = true
                        Task {
                            await viewModel.sendOTP(phoneNumber: phoneNumber)
                            isOTPOverlayVisible = true
                        }
                        //                        Task {
                        //                            await viewModel.signUpWithEmail(
                        //                                email: enteredEmail,
                        //                                password: enteredPassword,
                        //                                fullName: enteredFullName,
                        //                                phoneNumber: phoneNumber
                        //                            )
                        //                            isLoading = false
                        //                        }

                    }) {
                        Text("Send OTP")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal)

                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    
                    // Social Sign Up Options
                    VStack(spacing: 15) {
                        Text("OR")
                            .foregroundColor(.secondary)
                            .font(.footnote)

                        Button("Sign In with Google"){
                            Task {
                                isLoading = true
                                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let rootVC = scene.windows.first?.rootViewController {
                                    await viewModel.signInWithGoogle(presenting: rootVC)
                                }
                            }
                        }
                        .fontWeight(.semibold)
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal)
                        HStack(spacing: 20) {
//                                                        SocialButton(image: "apple.logo", action: {})
//                            GoogleSignInButton( scheme: .light , style: .wide ,state: .normal ) {
//
//                            }
//                            .padding(.horizontal,20)

//                                                        SocialButton(image: "phone.fill", action: {})
                        }
                    }
                    .padding(.vertical)

                    Spacer()

                    // Sign In Link
                    //                    HStack {
                    //                        Text("Already have an account?")
                    //                            .foregroundColor(.secondary)
                    //
                    //                        Button("Sign In") {
                    //                            isShowingSignIn = true
                    //                        }
                    //                        .foregroundColor(.customGreen)
                    //                        .fontWeight(.semibold)
                    //                    }
                    //                    .padding(.bottom, 30)
                }

                if viewModel.isAuthenticated {
                    Text("Authentication successful!")
                        .font(.headline)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(10)
                        .transition(.scale)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $isShowingSignIn) {
                SignInView()
            }
            .sheet(isPresented: $isOTPOverlayVisible) {
                OTPOverlayView(isPresented: $isOTPOverlayVisible, otpCode: $otpCode) {
                    Task {
                        await viewModel.verifyOTP(otpCode: otpCode)
                    }
                }
            }
            .alert(isPresented: Binding(
                get: { viewModel.showingError },
                set: { viewModel.showingError = $0 }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}



#Preview {
    SignUpView()
        .environment(AuthViewModel())
}
