//
//  CommunitiesView.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 14/02/25.
//

// CommunitiesView.swift
import SwiftUI

struct CommunitiesView: View {
    @Environment(CommunityViewModel.self) var viewModel : CommunityViewModel
    @State private var showNewCommunity = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: { showNewCommunity = true })
                    {
                        HStack {
                            Image(systemName: "plus.square.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.gray)

                            Text("New Community")
                                .font(.headline)
                                .padding(.leading, 10)
                        }
                    }
                }
                Section {
                    ForEach(viewModel.communities) { community in
                        NavigationLink(destination: CommunityDetailView(community: community))
                        {
                            CommunityRow(community: community)
                        }
                    }
                }
            }
            .navigationTitle("Communities")
            .sheet(isPresented: $showNewCommunity) { NewCommunityView() }
        }
    }
}


