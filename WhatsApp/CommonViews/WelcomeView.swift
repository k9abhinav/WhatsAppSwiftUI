import SwiftUI

struct WelcomeView: View {
    @State private var showSignUpView = false
    @State private var showPrivacyPolicy = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundImage()
                contentView
                    .padding()
                    .navigationDestination(isPresented: $showSignUpView) {
                        SignUpView()
                    }
                    .sheet(isPresented: $showPrivacyPolicy) {
                        PrivacyPolicyView()
                    }
            }
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 24) {
            topContentsView
            Spacer()
            bottomContentsView
            continueButton
        }
    }
    
    private var continueButton: some View {
        Button(action: { showSignUpView = true }) {
            Text("Agree & Continue")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.customGreen))
                .padding(.horizontal, 40)
        }
        .padding(.bottom, 40)
    }
    
    private var topContentsView: some View {
        VStack(spacing: 16) {
            LottieMessageDotsAnimationView()
            Text("Welcome to WhatsApp Clone.")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            Text("Simple. Secure. Reliable messaging.")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            LottieStarsAnimationView().scaleEffect(2)
        }
        .padding(.top, 40)
    }
    
    private var bottomContentsView: some View {
        VStack(spacing: 16) {
            Text("Read our Privacy Policy. Tap \"Continue\" to accept the Terms of Service.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(action: { showPrivacyPolicy = true }) {
                Text("Privacy Policy")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.customGreen)
            }
            .padding(.bottom, 8)
        }
    }
}

#Preview {
    WelcomeView()
}
