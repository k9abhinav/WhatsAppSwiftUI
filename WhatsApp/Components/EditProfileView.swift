
import SwiftUI

struct EditProfileView: View {
    let user: FireUserModel
    @Environment(FireUserViewModel.self) private var userViewModel: FireUserViewModel
    @Environment(FireAuthViewModel.self) private var authViewModel: FireAuthViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var userName: String
    @Binding var userStatus: String
    @State private var tempName: String = ""
    @State private var tempStatus: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("Personal Information").font(.headline).padding(.bottom)
                ) {
                    inputTextFields
                }
                .listRowSeparator(.hidden)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    saveButton
                }
            }
            .onAppear {
                tempName = userName
                tempStatus = userStatus
            }
        }
    }
    // MARK: COMPONENTS --------------------------------------------
    private var inputTextFields: some View {
        Group {
            TextField("Enter your name", text: $tempName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 10)
                .padding(.top,10)
            
            TextField("Add About", text: $tempStatus)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
        }
    }
    private var saveButton: some View {
        Button("Save") {
            userName = tempName
            userStatus = tempStatus
            userViewModel.updateUserName(userId: user.id , newName: tempName ){ error in
                if let error = error {
                    print("Failed to update name: \(error.localizedDescription)")
                } else {
                    print("User name updated successfully in Firestore!")
                }
            }
            userViewModel.updateUserStatus(userId: user.id , newStatus: tempStatus ){ error in
                if let error = error {
                    print("Failed to update status about info: \(error.localizedDescription)")
                } else {
                    print("status about info updated successfully in Firestore!")
                }
            }
            
            dismiss()
        }.bold()
    }
}


