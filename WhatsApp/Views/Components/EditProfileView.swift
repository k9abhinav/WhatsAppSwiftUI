//
//  EditProfileView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 27/02/25.
//

import SwiftUI

// ------------------------------------ EDIT PROFILE VIEW ----------------------------------------------------------

struct EditProfileView: View {
    @Binding var userName: String
    @Binding var userStatus: String
    @Environment(\.dismiss) var dismiss
    @State private var tempName: String = ""
    @State private var tempStatus: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information").font(.headline).padding(.bottom)) {

                    TextField("Enter your name", text: $tempName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 10)
                        .padding(.top,10)

                    TextField("Add About", text: $tempStatus)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }.listRowSeparator(.hidden)

            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        userName = tempName
                        userStatus = tempStatus
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear {
                tempName = userName
                tempStatus = userStatus
            }
        }
    }
}

//#Preview {
//    EditProfileView()
//}
