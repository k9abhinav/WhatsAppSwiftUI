
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
    @State private var otpCode: String = ""
    @State private var otpViewVisibilty: Bool = false
    @State private var signUpViewActive: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                BackgroundImage()
                VStack {
                    // Header
                    VStack(spacing: 20) {
                        Image("whatsapp")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)

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

                        TextField("Enter your phone number", text: $phoneNumber)
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
                            otpViewVisibilty = true
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
                        HStack {
                            Text("Next")
                                .fontWeight(.semibold)
                            Image(systemName: "chevron.right")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal)



                    // Social Sign Up Options
                    VStack(spacing: 15) {
                        Text("OR")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                        if isLoading {
                            withAnimation(.smooth) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                                    .frame(width: 20, height: 20)
                            }
                        }

                        Button(
                            action: {
                                Task {
                                    isLoading = true
                                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                       let rootVC = scene.windows.first?.rootViewController {
                                        await viewModel.signInWithGoogle(presenting: rootVC)
                                    }
                                }
                            }, label: {
                                HStack {
                                    Text("Sign in with Google")
                                    Image("googleIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                }
                            }
                        )
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(#colorLiteral(red: 0.262745098, green: 0.5254901961, blue: 0.9607843137, alpha: 1)))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .foregroundStyle(.white)
                        .buttonStyle(.automatic)
                        HStack(spacing: 20) {
                            //                                                        SocialButton(image: "apple.logo", action: {})
                            //                            GoogleSignInButton( scheme: .light , style: .wide ,state: .pressed ) {
                            //                                Task {
                            //                                    isLoading = true
                            //                                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                            //                                       let rootVC = scene.windows.first?.rootViewController {
                            //                                        await viewModel.signInWithGoogle(presenting: rootVC)
                            //                                    }
                            //                                }
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
                SignUpView()
            }
            .navigationDestination(isPresented: $signUpViewActive, destination:{
                SignUpView()
            })

            .navigationDestination(isPresented: $otpViewVisibilty, destination:{
                VerifyOTPView(isPresented: $otpViewVisibilty, otpCode: $otpCode) {
                    Task {
                        await viewModel.verifyOTP(otpCode: otpCode)
                    }
                }
            })
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

