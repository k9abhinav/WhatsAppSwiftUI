
import SwiftUI


struct NewCallView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("New Call To")) {
                    ForEach(["Alice", "Bob", "Charlie"], id: \.self) { contact in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.gray)

                            Text(contact)
                                .padding(.leading, 10)

                            Spacer()

                            HStack(spacing: 20) {
                                Button(action: {
                                    // Make audio call
                                }) {
                                    Image(systemName: "phone")
                                        .foregroundColor(.customGreen)
                                }

                                Button(action: {
                                    // Make video call
                                }) {
                                    Image(systemName: "video")
                                        .foregroundColor(.customGreen)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Contact")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search contacts")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

