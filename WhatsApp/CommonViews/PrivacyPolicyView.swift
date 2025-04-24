import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(policySections, id: \.content) { section in
                policyRow(title: section.title, content: section.content)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Exit") { dismiss() }
                }
            }
        }
    }

    private func policyRow(title: String?, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            Text(content)
                .font(.body)
        }
        .padding(.vertical, 6)
    }

    private let policySections: [(title: String?, content: String)] = [
        ("Privacy Policy", "Last updated: March 11, 2025"),
        ("Your Privacy Matters", "WhatsApp is committed to protecting your privacy and ensuring you have control over your information."),
        ("Information We Collect", """
        • Phone number: To create your account and verify your identity
        • Profile information: Name and profile photo (optional)
        • Contacts: To help you connect with other users (with permission)
        • Messages: End-to-end encrypted and not stored on our servers
        • Usage data: Anonymous data about app performance
        """),
        ("How We Use Your Information", """
        • Provide and improve our services
        • Connect you with other users
        • Ensure platform security
        • Assist with customer support
        • Comply with legal obligations
        """),
        ("End-to-End Encryption", "All messages sent through WhatsApp are protected with end-to-end encryption."),
        ("Your Choices and Rights", """
        You can:
        • Access and update your information in the app settings
        • Delete your account and associated data
        • Opt out of certain data collection
        • Request a copy of your data
        """),
        ("Security Measures", "We implement advanced security measures to protect your data."),
        (nil, "By using WhatsApp, you agree to the terms outlined in this Privacy Policy.")
    ]

}

#Preview {
    PrivacyPolicyView()
}
