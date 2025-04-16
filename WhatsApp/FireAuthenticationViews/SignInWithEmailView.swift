
import SwiftUI
import GoogleSignInSwift

struct SignInWithEmailView: View {
    @Environment(FireAuthViewModel.self) private var viewModel
    @State private var isShowingSignUp = false
    @State private var isLoading = false
    @State private var enteredPassword: String = ""
    @State private var enteredEmail: String = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    // Header
                    VStack(spacing: 20) {


                        Text("Welcome Back!")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Sign in with Email and Password to continue to WhatsApp Clone.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 70)

                    // Form Fields
                    VStack(spacing: 20) {
                        TextField("Email", text: $enteredEmail)
                        .modifier(TextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                        SecureField("Password", text: $enteredPassword)
                            .modifier(TextFieldStyle())

                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                // Implement forgot password
                            }
                            .foregroundColor(.customGreen)
                            .font(.footnote)
                            .padding(.trailing)
                        }
                    }
                    .padding(.vertical, 30)

                    // Sign In Button
                    Button(action: {
                        isLoading = true
                        Task {
                            await viewModel.signInWithEmail(email: enteredEmail, password: enteredPassword)
                            isLoading = false
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal)
                    .disabled(isLoading)


                    // Social Sign In Options
                    VStack(spacing: 15) {
                        Text("OR")
                            .foregroundColor(.secondary)
                            .font(.footnote)

                        HStack(spacing: 20) {
//                            SocialButton(image: "apple.logo", action: {})
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
                            .buttonStyle(PrimaryButtonStyle())
                            .padding()
//                            .frame(maxWidth: .infinity)
//                            .background(Color(#colorLiteral(red: 0.262745098, green: 0.5254901961, blue: 0.9607843137, alpha: 1)))
//                            .background(Color.customGreen)
//                            .cornerRadius(10)
//                            .padding(.horizontal)
//                            .foregroundStyle(.white)
//                            .buttonStyle(.automatic)
                        
//                            SocialButton(image: "g.circle.fill", action: {})
//                            SocialButton(image: "phone.fill", action: {})
                        }
                    }
                    .padding(.vertical)

                    Spacer()

                    // Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.secondary)

                        Button("Sign Up") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.customGreen)
                                            }
                    .padding(.bottom, 30)
                }

                if viewModel.userIsAuthenticated {
                    Text("Authentication successful!")
                        .font(.headline)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(10)
                        .transition(.scale)
                }
            }
            .navigationBarHidden(true)
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
    SignInWithEmailView()
        .environment(FireAuthViewModel())
}
