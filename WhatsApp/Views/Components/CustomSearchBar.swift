//
//  CustomSearchBar.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 27/02/25.
//

import SwiftUI

struct CustomSearchBar: View {
    @Binding var searchText: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 10)
                .frame(width: 30, height: 30)

            TextField("Ask Meta AI or Contacts", text: $searchText)
                .padding(.vertical, 10)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !searchText.isEmpty {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .onTapGesture {
                        searchText = "" // Reset search text to show all contacts
                    }
                    .padding(.trailing, 10)
            }
        }
        .background(Color.gray.opacity(0.1))

    }
}
