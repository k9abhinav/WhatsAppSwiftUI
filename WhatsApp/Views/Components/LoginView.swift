import SwiftUI

struct LoginView: View {
    @State private var phoneNumber: String = ""
    @State private var password: String = ""
    @AppStorage("isUserLoggedIn") private var isUserLoggedIn: Bool = false
    @State private var errorMessage: Bool = false
    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                Image("whatsapp")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding()

                Text("WhatsApp")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.green)

                Spacer()

                VStack(alignment: .leading, spacing: 15) {
                    TextField("Phone Number", text: $phoneNumber)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .keyboardType(.phonePad)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    if errorMessage {
                        Text("Invalid credentials")
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 40)

                Spacer()

                Button(action: {
                                  if validateLogin(phoneNumber: phoneNumber, password: password) {
                                      isUserLoggedIn = true
                                  } else {
                                      print("Invalid credentials")
                                      errorMessage = true
                                      DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                          errorMessage = false
                                      }
                                  }
                              }) {
                                  Text("Log In")
                                      .frame(minWidth: 0, maxWidth: .infinity)
                                      .padding()
                                      .background(Color.green)
                                      .foregroundColor(.white)
                                      .cornerRadius(8)
                                      .padding(.horizontal, 40)
                              }
                Spacer()

                HStack {
                    Text("Don't have an account?")
                    NavigationLink(destination: RegisterView()) {
                        Text("Sign Up")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
    }
    private func validateLogin(phoneNumber: String, password: String) -> Bool {
            // Implement your login validation logic here

            return phoneNumber == "1234567890" && password == "password"
        }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
