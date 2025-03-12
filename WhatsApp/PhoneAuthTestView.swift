import SwiftUI
import FirebaseAuth

struct PhoneAuthTestView: View {
    @State private var phoneNumber = ""
    @State private var otpCode = ""
    @State private var verificationID: String?
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Phone Authentication")
                .font(.largeTitle)

            TextField("Enter phone number", text: $phoneNumber)
                .keyboardType(.phonePad)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            if let _ = verificationID {
                TextField("Enter OTP", text: $otpCode)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                Button(action: verifyOTP) {
                    Text("Verify OTP")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            } else {
                Button(action: sendOTP) {
                    Text("Send OTP")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
    }

    func sendOTP() {
        guard !phoneNumber.isEmpty else {
            errorMessage = "Please enter a valid phone number."
            return
        }

        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                errorMessage = "Error sending OTP: \(error.localizedDescription)"
                return
            }
            self.verificationID = verificationID
            errorMessage = "OTP sent successfully."
        }
    }

    func verifyOTP() {
        guard let verificationID = verificationID else {
            errorMessage = "Verification ID not found."
            return
        }

        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: otpCode)

        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                errorMessage = "Error verifying OTP: \(error.localizedDescription)"
                return
            }
            errorMessage = "Phone number verified successfully."
        }
    }
}
