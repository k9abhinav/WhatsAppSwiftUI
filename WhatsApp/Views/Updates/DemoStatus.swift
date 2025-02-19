//
//  StatusUpdateView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 13/02/25.
//

import SwiftUI

struct StatusUpdateView: View {

    @State private var isPresented: Bool = false
    @State private var isFullScreenCoverPresented: Bool = false
    @State private var isSheetPresented: Bool = false
    @State private var showOverlay: Bool = false
    @State private var showsheet: Bool = false
    @State private var isPopoverPresented: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Button("Show Sheet") {
                isSheetPresented = true
            }

            Button("Show Full Screen Cover") {
                isFullScreenCoverPresented = true
            }

            Button("Show Popover") {
                isPopoverPresented = true
            }

            Button("Toggle Overlay") {
                showOverlay.toggle()
            }

             // Your main content
        }
        .navigationTitle("Presentations")
        .sheet(isPresented: $isSheetPresented) {
            SheetView(isPresented: $isSheetPresented)
        }
        .fullScreenCover(isPresented: $isFullScreenCoverPresented) {
            FullScreenCoverView(isPresented: $isFullScreenCoverPresented)
        }
        .popover(isPresented: $isPopoverPresented) {
            PopoverView(isPresented: $isPopoverPresented)
        }
        .overlay( // Overlay always on top (can be toggled)
            showOverlay ?
            Color.black.opacity(0.5) // Semi-transparent overlay
                .overlay(
                    VStack{
                        Text("Overlay Content")
                            .foregroundColor(.white)
                        Button("Dismiss Overlay") {
                            showOverlay.toggle()
                        }.foregroundStyle(.red)
                    }

                )
            : nil // No overlay
        )
    }
}




struct SheetView: View {
    @Binding var isPresented: Bool

    var body: some View{
        VStack{
            Text("This is sheet View")
            Button("Dismiss"){
                //                self.isPresented.toggle()
                isPresented = false
            }.foregroundStyle(.red).padding(.top,30)
        }.background(.gray).padding()

    }
}

struct FullScreenCoverView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Text("Full Screen Cover Content")
            Button("Dismiss Full Screen Cover") {
                isPresented = false
            }.foregroundStyle(.red).padding(.top,30)
        }
        .padding()
    }
}

struct PopoverView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Text("Popover Content")
            Button("Dismiss Popover") {
                isPresented = false
            }
        }
        .padding()
        .background(Color.secondary)
    }
}


//Previews

#Preview {
    StatusUpdateView()
}
