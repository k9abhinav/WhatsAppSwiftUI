//
//  NewCommunityView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 04/03/25.
//

import SwiftUI

struct NewCommunityView: View {
    @Environment(\.dismiss) var dismiss
    @State private var communityName = ""
    @State private var communityDescription = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Community Info")) {
                    TextField("Community Name", text: $communityName)
                    TextField("Description", text: $communityDescription)
                }
            }
            .navigationTitle("New Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        // Create community action
                        dismiss()
                    }
                    .disabled(communityName.isEmpty)
                }
            }
        }
    }
}
