//
//  OTPOverlayView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 10/03/25.
//
import SwiftUI

struct OTPOverlayView: View {
    @Binding var isPresented: Bool
    @Binding var otpCode: String
    var onVerify: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Enter OTP")
                    .font(.title2)
                    .fontWeight(.bold)
                
                TextField("OTP Code", text: $otpCode)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .frame(width: 250)
                
                HStack(spacing: 20) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    
                    Button("Verify") {
                        onVerify()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 10)
        }
    }
}
