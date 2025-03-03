//
//  AddStatusView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 26/02/25.
//

import SwiftUI
import PhotosUI

struct AddUpdatesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var statusText = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 120)

                    if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                Button(action: {
                                    selectedImageData = nil
                                    selectedItem = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .padding(8),
                                alignment: .topTrailing
                            )
                    }
                    else {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            VStack {
                                Image(systemName: "photo")
                                    .font(.caption)
                                Text("Add Photo")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
                        .onChange(of: selectedItem) { oldValue, newValue in
                            Task {
                                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)

                TextField("What's on your mind?", text: $statusText, axis: .vertical)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)

                Button(action: saveStatus) {
                    Text("Post Status")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(statusText.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                .disabled(statusText.isEmpty)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Add Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveStatus() {
        let newStatus = Update(content: statusText, imageData: selectedImageData)
        modelContext.insert(newStatus)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving status: \(error)")
        }
    }
}


#Preview {
    AddUpdatesView()
}
