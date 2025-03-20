//
//  WelcomeScreen.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 11/03/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var showSignUpView = false
    @State private var showPrivacyPolicy = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundImage()
                VStack(spacing: 24) {

                    VStack(spacing: 16) {

//                                                LottieWhatsAppView()
                        LottieMessageDotsAnimationView()
//                        Image("welcome_image")
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: 80, height: 80)
//                            .border(Color.gray, width: 1)

                        Text("Welcome to WhatsApp Clone.")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)


                        Text("Simple. Secure. Reliable messaging.")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

//                        LottieStarsAnimationView()
//                            .scaleEffect(2)

                    }
                    .padding(.top, 40)

                    Spacer()

                    // Privacy policy section
                    VStack(spacing: 16) {


                        Text("Read our Privacy Policy. Tap \"Continue\" to accept the Terms of Service.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button {
                            showPrivacyPolicy = true
                        } label: {
                            Text("Privacy Policy")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.customGreen)
                        }
                        .padding(.bottom, 8)
                    }

                    // Continue button
                    Button {
                        showSignUpView = true
                    } label: {
                        Text("Agree & Continue")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.customGreen)
                            )
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 40)
                }
                .padding()
                .navigationDestination(isPresented: $showSignUpView) {
                    withAnimation(.smooth) {
                        SignUpView()
                    }
                }
                .sheet(isPresented: $showPrivacyPolicy) {
                    withAnimation(.smooth) {
                        PrivacyPolicyView()
                    }
                
                }
            }
        }
    }
}



#Preview {
    WelcomeView()
}



