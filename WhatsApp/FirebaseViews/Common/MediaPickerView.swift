//
//  MediaPickerView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 14/04/25.
//


import SwiftUI
import MediaPlayer

struct MediaPickerView: UIViewControllerRepresentable {
    @Binding var selectedMedia: MPMediaItem?

    func makeUIViewController(context: Context) -> MPMediaPickerController {
        let mediaPicker = MPMediaPickerController(mediaTypes: .music)
        mediaPicker.delegate = context.coordinator
        mediaPicker.allowsPickingMultipleItems = false
        mediaPicker.showsCloudItems = true
        return mediaPicker
    }

    func updateUIViewController(_ uiViewController: MPMediaPickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MPMediaPickerControllerDelegate {
        let parent: MediaPickerView

        init(_ parent: MediaPickerView) {
            self.parent = parent
        }

        func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
            mediaPicker.dismiss(animated: true, completion: nil)
            parent.selectedMedia = mediaItemCollection.items.first
        }

        func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
            mediaPicker.dismiss(animated: true, completion: nil)
        }
    }
}
