//
//  PrivacyPolicyView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 11/03/25.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack{
               backGroundImage
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Group {
                            Text("Privacy Policy")
                                .font(.title)
                                .fontWeight(.bold)
                                .padding(.bottom, 8)

                            Text("Last updated: March 11, 2025")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 16)

                            Text("Your Privacy Matters")
                                .font(.headline)
                                .fontWeight(.semibold)

                            Text("WhatsApp is committed to protecting your privacy and ensuring you have control over your information. This Privacy Policy explains how we collect, use, and safeguard your data.")
                                .font(.body)
                                .padding(.bottom, 8)

                            Text("Information We Collect")
                                .font(.headline)
                                .fontWeight(.semibold)

                            Text("• Phone number: To create your account and verify your identity\n• Profile information: Name and profile photo (optional)\n• Contacts: To help you connect with other users (with permission)\n• Messages: End-to-end encrypted and not stored on our servers\n• Usage data: Anonymous data about app performance")
                                .font(.body)
                                .padding(.bottom, 8)

                            Text("How We Use Your Information")
                                .font(.headline)
                                .fontWeight(.semibold)

                            Text("• Provide and improve our services\n• Connect you with other users\n• Ensure platform security\n• Assist with customer support\n• Comply with legal obligations")
                                .font(.body)
                                .padding(.bottom, 8)
                        }

                        Group {
                            Text("End-to-End Encryption")
                                .font(.headline)
                                .fontWeight(.semibold)

                            Text("All messages sent through WhatsApp are protected with end-to-end encryption. This means that only you and the person you're communicating with can read what's sent, and nobody in between, not even WhatsApp.")
                                .font(.body)
                                .padding(.bottom, 8)

                            Text("Your Choices and Rights")
                                .font(.headline)
                                .fontWeight(.semibold)

                            Text("You can:\n• Access and update your information in the app settings\n• Delete your account and associated data\n• Opt out of certain data collection\n• Request a copy of your data")
                                .font(.body)
                                .padding(.bottom, 8)

                            Text("Security Measures")
                                .font(.headline)
                                .fontWeight(.semibold)

                            Text("We implement advanced technical and organizational security measures to protect your data from unauthorized access, disclosure, alteration, and destruction.")
                                .font(.body)
                                .padding(.bottom, 8)

                            Text("By using WhatsApp, you agree to the terms outlined in this Privacy Policy. We may update this policy from time to time, and we will notify you of any significant changes.")
                                .font(.body)
                                .padding(.bottom, 16)
                        }
                    }
                    .padding()
                }
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Exit") {
                        dismiss()
                    }
                }
            }
        }
    }
//    --- Components
    private var backGroundImage: some View {
        Image("logo")
            .resizable()
            .scaledToFit()
//            .scaleEffect(1.4)
            .opacity(0.1)
    }
}
#Preview {
    PrivacyPolicyView()
}
