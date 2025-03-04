
import SwiftUI

struct CallsView: View {
    @Environment(CallsViewModel.self) var viewModel : CallsViewModel
    @State private var showNewCallSheet = false

    var body: some View {
        NavigationView {
            List {
                // Create Call Link Section
                Section {
                    HStack {
                        Image(systemName: "link")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .foregroundColor(.green)
                            .padding(8)
                            .background(Color.green.opacity(0.2))
                            .clipShape(Circle())

                        VStack(alignment: .leading) {
                            Text("Create call link")
                                .font(.headline)
                            Text("Share a link for your WhatsApp call")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.leading, 10)
                    }
                    .padding(.vertical, 5)
                }

                // Recent Calls Section
                Section(header: Text("Recent")) {
                    ForEach(viewModel.calls) { call in
                        CallRow(call: call)

                    }
                }
            }
            .navigationTitle("Calls")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showNewCallSheet = true
                    }) {
                        Image(systemName: "phone.badge.plus")
                            .foregroundColor(.green)
                    }
                }
            }
            .sheet(isPresented: $showNewCallSheet) {
                NewCallView()
            }
        }
    }

}



