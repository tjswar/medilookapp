import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    let onSubmit: () -> Void
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.secondaryText)
                    .padding(.leading, 12)
                
                TextField("Search medicines...", text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        onSubmit()
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .padding(.trailing, 8)
                }
            }
            .padding(.vertical, 12)
            .background(AppColors.searchBarBackground)
            .cornerRadius(15)
            .shadow(color: AppColors.shadow, radius: 5, x: 0, y: 2)
        }
    }
}

#Preview {
    SearchBarView(text: .constant(""), onSubmit: {})
        .padding()
        .background(AppColors.primaryGradient)
} 