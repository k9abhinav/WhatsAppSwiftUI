//
//  RegisterView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 27/02/25.
//

import SwiftUI

struct RegisterView: View {
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var password: String = ""

    var body: some View {
        VStack {
            Spacer()

            Image("whatsapp")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
                .padding()

            Text("Sign Up")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.green)

            Spacer()

            VStack(alignment: .leading, spacing: 15) {
                TextField("Name", text: $name)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)

                TextField("Phone Number", text: $phoneNumber)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .keyboardType(.phonePad)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 40)

            Spacer()

            Button(action: {
                // Handle sign-up action
                print("Sign up button tapped")
            }) {
                Text("Sign Up")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
        .navigationBarTitle("Register", displayMode: .inline)
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
