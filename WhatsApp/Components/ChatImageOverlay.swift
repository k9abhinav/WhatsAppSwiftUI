//
//  ProfilePicOverlay 2.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 16/04/25.
//


import SwiftUI

struct ChatImageOverlay : View {
    let message:FireMessageModel?
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            VStack{
                Color.black
                    .ignoresSafeArea(.all)
            }
            VStack {
                Spacer()
                // Profile Image
                if let imageUrlString = message?.imageUrl, let imageUrl = URL(string: imageUrlString) {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .background(.white)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: 400) // Adjust height as needed
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(radius: 10)
                                .padding()
                        case .failure:
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
        }
        .zIndex(10)
        .onTapGesture { onDismiss() }
        .transition(.opacity) // Smooth fade-in effect
        .animation(.easeInOut(duration: 0.3), value: message?.imageUrl) // Smooth appearance
    }
}
