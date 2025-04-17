//
//  HelperViews.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 17/04/25.
//

import SwiftUI
import AVFoundation
import AVKit
// MARK: - Helper Views
struct ProgressBar: View {
    var value: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: 2)
                    .opacity(0.3)
                    .foregroundColor(.gray)

                Rectangle()
                    .frame(width: min(CGFloat(value) * geometry.size.width, geometry.size.width), height: 2)
                    .foregroundColor(.white)
                    .animation(.linear, value: value)
            }
        }
        .frame(height: 2)
    }
}

struct AsyncImageView<Content: View>: View {
    private let url: URL
    private let content: (AsyncImagePhase) -> Content

    init(url: URL, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
    }

    var body: some View {
        AsyncImage(url: url, content: content)
    }
}

struct VideoThumbnailView: View {
    let videoURL: URL
    @State private var thumbnail: UIImage?

    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .overlay(
                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40)
                            .foregroundColor(.white)
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "video.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40)
                            .foregroundColor(.gray)
                    )
            }
        }
        .onAppear {
            generateThumbnail()
        }
    }

    private func generateThumbnail() {
        let asset = AVURLAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        Task {
            do {
                let cgImage = try await imageGenerator.image(at: CMTime(seconds: 0, preferredTimescale: 1)).image
                self.thumbnail = UIImage(cgImage: cgImage)
            } catch {
                print("❌ Error generating thumbnail: \(error.localizedDescription)")
            }
        }
    }
}

struct VideoPlayerView: View {
    let url: URL

    var body: some View {
        VideoPlayer(player: AVPlayer(url: url))
            .onAppear {
                AVPlayer(url: url).play()
            }
    }
}

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView

        init(_ parent: ImagePickerView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct DocumentPickerView: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.movie, .video, .quickTimeMovie])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView

        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }

            // Create a local copy in app's temporary directory
            let tempDir = FileManager.default.temporaryDirectory
            let localURL = tempDir.appendingPathComponent(url.lastPathComponent)

            do {
                // Remove any existing file
                try? FileManager.default.removeItem(at: localURL)

                // Copy file to local storage
                try FileManager.default.copyItem(at: url, to: localURL)

                // Use the local URL
                parent.selectedURL = localURL
            } catch {
                print("❌ Error copying file: \(error.localizedDescription)")
            }

            parent.dismiss()
        }
    }
}

// Extension for supporting identifiable error messages
/*
 The @retroactive attribute in Swift is used to indicate retroactive conformances. Retroactive conformance occurs when you extend a type from one module to conform to a protocol from another module. This is useful when you don't own either the type or the protocol but want to make them work together.

 For example:

 swift
 extension SomeImportedType: @retroactive SomeProtocol {
     // Implementation of protocol requirements
 }
 However, there are limitations:

 The @retroactive attribute is only applicable in specific scenarios, such as when the type and protocol are from different modules.

 It helps avoid conflicts if the original module later introduces its own conformance.
 */
extension String: @retroactive Identifiable {
    public var id: String { self }
}
