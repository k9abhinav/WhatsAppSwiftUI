
import SwiftUI

struct CustomSearchBar: View {

    @Binding var searchText: String
    @State var placeholderText: String
    @FocusState var isFocused: Bool

    var body: some View {
        HStack {
            magnifyingGlassSymbol
            searchBar
            if !searchText.isEmpty { crossButton }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(style: StrokeStyle(lineWidth: 3))
                .foregroundColor( isFocused ? Color.customGreen : Color.clear)
        }
        .background(Color.gray.opacity(0.1))
    }

    // MARK: Components -------------------------

    private var magnifyingGlassSymbol: some View {
        Image(systemName: "magnifyingglass")
            .foregroundColor(.gray)
            .padding(.leading, 10)
            .frame(width: 30, height: 30)
    }
    private var searchBar : some View {
        TextField(placeholderText, text: $searchText)
            .padding(.vertical, 10)
            .focused($isFocused)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

    }

    private var crossButton: some View {
        Image(systemName: "xmark.circle.fill")
            .foregroundColor(.gray)
            .onTapGesture { searchText = "" }
            .padding(.trailing, 10)
    }
}
