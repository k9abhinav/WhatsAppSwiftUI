//
//  TestRowView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 09/04/25.
//

import SwiftUI
struct TestRowView: View {
    @Environment(FireUserViewModel.self) var userViewModel:FireUserViewModel
    let userId:String
    var user: FireUserModel {
        userViewModel.allUsers.first { $0.id == userId } ?? FireUserModel(name: "Unknown")
    }
    var body: some View {
        Text("Name in RowView :  \(user.name)")
    }
}

//#Preview {
//    TestRowView()
//}
