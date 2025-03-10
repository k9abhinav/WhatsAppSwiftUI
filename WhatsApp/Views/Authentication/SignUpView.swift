//
//  SignUpView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 07/03/25.
//

import SwiftUI

// MARK: - Custom Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(UIColor(red: 0.22, green: 0.67, blue: 0.49, alpha: 1.0)))
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

struct TextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
    }
}

// MARK: - SignUp View
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
                        Image(systemName: "message.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
                            .foregroundColor(Color(UIColor(red: 0.22, green: 0.67, blue: 0.49, alpha: 1.0)))

                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Sign up to get started with WhatsApp Clone")
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

                        HStack(spacing: 20) {
                            //                            SocialButton(image: "apple.logo", action: {})
                            SocialButton(image: "g.circle.fill", action: {
                                Task {
                                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                       let rootVC = scene.windows.first?.rootViewController {
                                        await viewModel.signInWithGoogle(presenting: rootVC)
                                    }
                                }
                            })
                            //                            SocialButton(image: "phone.fill", action: {})
                        }
                    }
                    .padding(.vertical)

                    Spacer()

                    // Sign In Link
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.secondary)

                        Button("Sign In") {
                            isShowingSignIn = true
                        }
                        .foregroundColor(Color(UIColor(red: 0.22, green: 0.67, blue: 0.49, alpha: 1.0)))
                        .fontWeight(.semibold)
                    }
                    .padding(.bottom, 30)
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

struct SocialButton: View {
    let image: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .padding()
                .background(Color(UIColor.systemGray6))
                .clipShape(Circle())
        }
    }
}

#Preview {
    SignUpView()
        .environment(AuthViewModel())
}
