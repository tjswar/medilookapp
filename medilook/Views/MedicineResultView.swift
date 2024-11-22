import SwiftUI

struct MedicineResultView: View {
    let medicine: Medicine
    let targetLanguage: String
    @ObservedObject var viewModel: MedicineViewModel
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with Name and Prescription Badge
            HStack(alignment: .center) {
                Text(medicine.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if medicine.requiresPrescription {
                    Text("Rx Only")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.8))
                        .clipShape(Capsule())
                }
            }
            
            // Concise Description (always visible)
            if let firstSentence = medicine.description.split(separator: ".").first {
                Text(String(firstSentence) + ".")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Key Information (always visible)
            HStack(spacing: 16) {
                // Dosage Pill
                if !medicine.dosage.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "pills.fill")
                            .foregroundColor(.blue)
                        Text(medicine.dosage.split(separator: ".").first.map(String.init) ?? medicine.dosage)
                            .lineLimit(1)
                    }
                    .font(.caption)
                }
                
                Spacer()
                
                // Show More/Less Button
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Text(isExpanded ? "Show Less" : "Show More")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if isExpanded {
                // Warnings Section (only important ones)
                if !medicine.warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Important Information")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        
                        ForEach(medicine.warnings.prefix(1), id: \.self) { warning in
                            if let mainWarning = warning.split(separator: ".").first {
                                Label(String(mainWarning) + ".", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red.opacity(0.8))
                                    .lineLimit(2)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Side Effects (most common only)
                if !medicine.sideEffects.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Common Side Effects")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 8) {
                            ForEach(medicine.sideEffects.prefix(3), id: \.self) { effect in
                                if let mainEffect = effect.split(separator: ".").first {
                                    Text(String(mainEffect))
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                }
                
                // Alternatives (if any)
                if !medicine.alternatives.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Also Known As")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(medicine.alternatives.prefix(2), id: \.self) { alt in
                                    Text(alt)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    MedicineResultView(
        medicine: Medicine(
            name: "Sample Medicine",
            description: "Sample description with a longer text that might need to be expanded to show the full content",
            alternatives: ["Alt 1", "Alt 2", "Alt 3", "Alt 4", "Alt 5"],
            rxcui: "12345",
            dosage: "500mg twice daily",
            warnings: ["Do not exceed recommended dose", "Avoid alcohol"],
            requiresPrescription: true,
            sideEffects: ["Drowsiness", "Nausea", "Headache"],
            usageInstructions: "Take with food and water"
        ),
        targetLanguage: "English",
        viewModel: MedicineViewModel()
    )
    .padding()
} 