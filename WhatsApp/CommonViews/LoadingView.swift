//
//  LoadingView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 18/03/25.
//
import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "ellipsis.message.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.customGreen)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
            
            Text("Loading...")
                .font(.title2)
                .foregroundColor(.gray)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .customGreen))
                .scaleEffect(1.5)
        }
        .onAppear {
            isAnimating = true
        }
    }
}
