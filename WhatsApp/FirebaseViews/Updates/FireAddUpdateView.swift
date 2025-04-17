//
//  FireAddUpdateView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 17/04/25.
//

import SwiftUI

struct FireAddUpdateView: View {
    @Environment(FireUpdateViewModel.self) private var updateViewModel : FireUpdateViewModel
    @Environment(\.dismiss) private var dismiss
    let userId: String
    @State private var content: String = ""
    @State private var selectedMediaType: FireUpdateModel.MediaType = .text
    @State private var showImagePicker = false
    @State private var showVideoPicker = false
    @State private var selectedImage: UIImage?
    @State private var selectedVideoURL: URL?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Status")) {
                    TextField("What's on your mind?", text: $content)
                        .submitLabel(.done)
                }
                
                Section(header: Text("Media Type")) {
                    Picker("Media Type", selection: $selectedMediaType) {
                        Text("Text Only").tag(FireUpdateModel.MediaType.text)
                        Text("Image").tag(FireUpdateModel.MediaType.image)
                        Text("Video").tag(FireUpdateModel.MediaType.video)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if selectedMediaType == .image && selectedImage != nil {
                    Section {
                        Image(uiImage: selectedImage!)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                if selectedMediaType == .video && selectedVideoURL != nil {
                    Section {
                        VideoThumbnailView(videoURL: selectedVideoURL!)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                Section {
                    switch selectedMediaType {
                    case .text:
                        EmptyView()
                    case .image:
                        Button("Select Image") {
                            showImagePicker = true
                        }
                    case .video:
                        Button("Select Video") {
                            showVideoPicker = true
                        }
                    }
                }
                
                Section {
                    Button(action: addUpdate) {
                        HStack {
                            Spacer()
                            Text("Post Update")
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("New Update")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showVideoPicker) {
                DocumentPickerView(selectedURL: $selectedVideoURL)
            }
            .overlay {
                if updateViewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Uploading...")
                                .foregroundColor(.white)
                                .padding(.top)
                        }
                        .padding(30)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        if content.isEmpty {
            return false
        }
        
        switch selectedMediaType {
        case .text:
            return true
        case .image:
            return selectedImage != nil
        case .video:
            return selectedVideoURL != nil
        }
    }
    
    private func addUpdate() {
        Task {
            switch selectedMediaType {
            case .text:
                await updateViewModel.addTextUpdate(for: userId, content: content)
                
            case .image:
                if let image = selectedImage {
                    await updateViewModel.addImageUpdate(for: userId, content: content, image: image)
                }
                
            case .video:
                if let videoURL = selectedVideoURL {
                    await updateViewModel.addVideoUpdate(for: userId, content: content, videoURL: videoURL)
                }
            }
            
            dismiss()
        }
    }
}


