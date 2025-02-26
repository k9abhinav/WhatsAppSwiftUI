//
//  StatusDetailView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 26/02/25.
//

import Foundation
import SwiftUI

struct StatusDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let status: Status

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Button(action: {
                        deleteStatus()
                        dismiss()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding()

                Spacer()

                if let imageData = status.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                        .padding(.horizontal)
                }

                Text(status.content)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(12)
                    .padding()

                Spacer()

                Text(status.timeRemaining)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom)
            }
        }
    }

    private func deleteStatus() {
        modelContext.delete(status)
        do {
            try modelContext.save()
        } catch {
            print("Error deleting status: \(error)")
        }
    }
}
