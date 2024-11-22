import SwiftUI

struct HeaderView: View {
    @Binding var animateLogo: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 10) {
            Text("MediLook")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .padding(.top, 10)
    }
}

#Preview {
    HeaderView(animateLogo: .constant(false))
} 
