//
//  ImagePreviewView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 16/04/25.
//
import SwiftUI

struct ImagePreviewView: View {
    let image: UIImage
    var onSend: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack {
            Spacer()
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .cornerRadius(12)
                .padding()

            HStack(spacing: 20) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }

                Button(action: onSend) {
                    Text("Send")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}
