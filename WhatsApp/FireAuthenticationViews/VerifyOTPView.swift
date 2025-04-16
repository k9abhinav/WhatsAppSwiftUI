//
//  OTPOverlayView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 10/03/25.
//
import SwiftUI

struct VerifyOTPView: View {
    @Binding var isPresented: Bool
    @Binding var otpCode: String
    var onVerify: () -> Void

    var body: some View {
        ZStack {
            BackgroundImage()


            VStack(spacing: 20) {
                Text("Enter your code to verify you phone number")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .fontWeight(.semibold)
                TextField("OTP Code", text: $otpCode)
                    .keyboardType(.numberPad)
                    .modifier(TextFieldStyle())

                    Button("Verify OTP") {
                        onVerify()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal)

            }
            .navigationBarBackButtonHidden(true)
            .toolbar{
                ToolbarItem(placement: .topBarLeading) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                }
            }
            .padding()
            .padding(.top, 80)
            .cornerRadius(12)
        }
    }
}

#Preview {
    VerifyOTPView(isPresented: .constant(true), otpCode: .constant(""), onVerify: { })
}
