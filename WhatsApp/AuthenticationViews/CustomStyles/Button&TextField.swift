//
//  PrimaryButtonStyle.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 11/03/25.
//

import SwiftUI

// MARK: - Custom Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.customGreen)
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
