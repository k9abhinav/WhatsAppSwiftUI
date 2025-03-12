//
//  BackgroundImage.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 12/03/25.
//

import SwiftUI

struct BackgroundImage: View {
    var body: some View {
        Image("bgChats")
            .resizable()
            .opacity(0.3)
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    BackgroundImage()
}
