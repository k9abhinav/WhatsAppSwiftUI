//
//  ProfilePicView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 27/02/25.
//

import SwiftUI

struct ProfilePicView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            if let imageData = user.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .background(Color.black.opacity(0.9))
                    .ignoresSafeArea()
            } else {
                Image(systemName: "person.crop.circle.fill") // Default image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }
        }

        .onTapGesture {
            dismiss()
        }
    }
}
//
//#Preview {
//    ProfilePicView()
//}
