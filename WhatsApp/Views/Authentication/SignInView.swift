//
//  SignInView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 07/03/25.
//

import SwiftUI

struct SignInView: View {
    @Environment(AuthViewModel.self) private var viewModel
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
                        Image(systemName: "message.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
                            .foregroundColor(Color(UIColor(red: 0.22, green: 0.67, blue: 0.49, alpha: 1.0)))

                        Text("Welcome Back")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Sign in to continue to WhatsApp Clone")
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
                            .foregroundColor(Color(UIColor(red: 0.22, green: 0.67, blue: 0.49, alpha: 1.0)))
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
                            SocialButton(image: "apple.logo", action: {})
                            SocialButton(image: "g.circle.fill", action: {})
                            SocialButton(image: "phone.fill", action: {})
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
    SignInView()
        .environment(AuthViewModel())
}
