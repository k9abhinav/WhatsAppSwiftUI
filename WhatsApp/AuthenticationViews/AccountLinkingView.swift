
import SwiftUI

struct AccountLinkingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FireAuthViewModel.self) private var authViewModel
    
    @State private var password = ""
    @State private var isLinking = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Link Your Google Account")
                    .font(.title)
                    .bold()
                
                Text("We found an existing account with this email. Enter your password to link your Google account.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                Button {
                    linkAccounts()
                } label: {
                    if isLinking {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Link Accounts")
                            .fontWeight(.semibold)
                    }
                }
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(password.isEmpty || isLinking)
                
                Button("Cancel") {
                    authViewModel.pendingGoogleCredential = nil
                    authViewModel.showAccountLinkingPrompt = false
                    dismiss()
                }
                .foregroundColor(.blue)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
//            .alert(isPresented: authViewModel.showingError) {
//                Alert(
//                    title: Text("Error"),
//                    message: Text(authViewModel.errorMessage),
//                    dismissButton: .default(Text("OK"))
//                )
//            }
        }
    }
    
    private func linkAccounts() {
        guard let email = authViewModel.currentLoggedInUser?.email else {
            return
        }
        
        isLinking = true
        
        Task {
            await authViewModel.completeGoogleAccountLinking(email: email, password: password)
            DispatchQueue.main.async {
                isLinking = false
                if !authViewModel.showingError {
                    dismiss()
                }
            }
        }
    }
}
