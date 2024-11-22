import SwiftUI

struct SearchHistoryView: View {
    @ObservedObject var viewModel: MedicineViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                if viewModel.searchHistory.isEmpty {
                    emptyHistoryView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(viewModel.searchHistory) { history in
                                HistoryItemView(history: history)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Search History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var emptyHistoryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 50))
                .foregroundStyle(AppColors.primaryGradient)
            
            Text("No Search History")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.text)
            
            Text("Your search history will appear here")
                .font(.subheadline)
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct HistoryItemView: View {
    let history: SearchHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(history.query)
                    .font(.headline)
                    .foregroundColor(AppColors.text)
                
                Spacer()
                
                Text(history.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Text("\(history.results.count) results found")
                .font(.subheadline)
                .foregroundColor(AppColors.primary)
            
            if let firstResult = history.results.first {
                Text(firstResult.name)
                    .font(.subheadline)
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(1)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    SearchHistoryView(viewModel: MedicineViewModel())
} 