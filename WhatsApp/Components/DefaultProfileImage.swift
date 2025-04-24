//
//  DefaultProfileImage.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 23/04/25.
//

import SwiftUI

struct DefaultProfileImage: View {
    let size: CGFloat
    var body: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .foregroundColor(.secondary)
    }
}

#Preview {
    DefaultProfileImage(size: 50)
}
