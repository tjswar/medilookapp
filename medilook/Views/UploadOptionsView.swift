import SwiftUI
import UniformTypeIdentifiers
import Vision

struct UploadOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var recognizedText: String = ""
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @ObservedObject var viewModel: MedicineViewModel
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        showingCamera = true
                    }) {
                        HStack {
                            Image(systemName: "camera")
                                .frame(width: 30)
                            Text("Take Photo")
                        }
                    }
                    
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                                .frame(width: 30)
                            Text("Choose from Photos")
                        }
                    }
                } header: {
                    Text("Select Source")
                } footer: {
                    Text("Supported formats: Images (JPEG, PNG)")
                }
            }
            .navigationTitle("Upload Prescription")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
                    .onChange(of: selectedImage) { oldValue, newValue in
                        if let image = newValue {
                            processImage(image)
                        }
                    }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
                    .onChange(of: selectedImage) { oldValue, newValue in
                        if let image = newValue {
                            processImage(image)
                        }
                    }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isProcessing {
                    ProgressView("Processing image...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
    }
    
    private func processImage(_ image: UIImage) {
        isProcessing = true
        
        guard let cgImage = image.cgImage else {
            showError(message: "Failed to process image")
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                showError(message: "Text recognition failed: \(error.localizedDescription)")
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                showError(message: "No text found in image")
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            // Process the recognized text
            DispatchQueue.main.async {
                self.recognizedText = recognizedStrings.joined(separator: " ")
                print("Recognized Text: \(self.recognizedText)") // Debug print
                
                // Extract and search for medicine names
                let potentialMedicineNames = extractMedicineNames(from: self.recognizedText)
                if !potentialMedicineNames.isEmpty {
                    searchMedicines(names: potentialMedicineNames)
                } else {
                    showError(message: "No medicine names found in the prescription")
                }
            }
        }
        
        // Configure text recognition request
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        do {
            try requestHandler.perform([request])
        } catch {
            showError(message: "Failed to process image: \(error.localizedDescription)")
        }
    }
    
    private func extractMedicineNames(from text: String) -> [String] {
        // Split text into lines
        let lines = text.components(separatedBy: .newlines)
        var medicineNames: Set<String> = []
        
        // Common prescription indicators
        let prescriptionIndicators = [
            "rx",
            "prescribed",
            "prescription",
            "medication"
        ]
        
        for line in lines {
            let lowercasedLine = line.lowercased()
            
            // Check if line contains a prescription indicator
            if prescriptionIndicators.contains(where: { lowercasedLine.contains($0) }) {
                // Split the line into words
                let words = line.components(separatedBy: .whitespaces)
                var foundMedicine = false
                var medicineName: [String] = []
                
                for word in words {
                    let lowercasedWord = word.lowercased()
                    
                    // If we find Rx or similar, start capturing the next words as medicine name
                    if prescriptionIndicators.contains(where: { lowercasedWord.contains($0) }) {
                        foundMedicine = true
                        continue
                    }
                    
                    // If we're capturing medicine name
                    if foundMedicine {
                        // Stop if we hit numbers or dosage information
                        if word.contains(where: { $0.isNumber }) ||
                           lowercasedWord.contains("mg") || 
                           lowercasedWord.contains("tablet") || 
                           lowercasedWord.contains("capsule") ||
                           lowercasedWord.contains("tid") ||
                           lowercasedWord.contains("bid") ||
                           lowercasedWord.contains("daily") {
                            break
                        }
                        
                        // Add word to medicine name if it's not a common word
                        if !lowercasedWord.contains("patient") &&
                           !lowercasedWord.contains("name") &&
                           !lowercasedWord.contains("address") &&
                           !lowercasedWord.contains("date") &&
                           !lowercasedWord.contains("dr.") &&
                           !lowercasedWord.contains("prescribed") {
                            medicineName.append(word)
                        }
                    }
                }
                
                // Process the medicine name if we found one
                if !medicineName.isEmpty {
                    let name = medicineName.joined(separator: " ")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if name.count > 2 {
                        medicineNames.insert(name)
                    }
                }
            }
        }
        
        print("Found medicine names: \(medicineNames)") // Debug print
        return Array(medicineNames)
    }
    
    private func searchMedicines(names: [String]) {
        print("Searching for medicines: \(names)") // Debug print
        
        // Search for each medicine name
        for name in names {
            // Skip very short names and common words
            if name.count > 2 && !["tablet", "capsule", "dose", "take"].contains(name.lowercased()) {
                viewModel.searchMedicine(query: name)
            }
        }
        
        // Dismiss the view after a short delay to allow searches to start
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isProcessing = false
            self.dismiss()
        }
    }
    
    private func showError(message: String) {
        DispatchQueue.main.async {
            errorMessage = message
            showError = true
            isProcessing = false
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes: [UTType] = [
            .image,
            .pdf,
            .jpeg,
            .png,
            .text
        ]
        
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let selectedURL = urls.first else { return }
            
            // Start accessing the security-scoped resource
            let didStartAccessing = selectedURL.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    selectedURL.stopAccessingSecurityScopedResource()
                }
            }
            
            // Handle different file types
            let fileType = UTType(filenameExtension: selectedURL.pathExtension.lowercased())
            
            do {
                switch fileType {
                case .some(.pdf):
                    if let pdfImage = convertPDFToImage(url: selectedURL) {
                        DispatchQueue.main.async {
                            self.parent.selectedImage = pdfImage
                        }
                    }
                case .some(.jpeg), .some(.png), .some(.image):
                    let imageData = try Data(contentsOf: selectedURL)
                    if let image = UIImage(data: imageData) {
                        DispatchQueue.main.async {
                            self.parent.selectedImage = image
                        }
                    }
                default:
                    print("Unsupported file type")
                }
            } catch {
                print("Error processing file: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }
        
        private func convertPDFToImage(url: URL) -> UIImage? {
            guard let document = CGPDFDocument(url as CFURL),
                  let page = document.page(at: 1) else { return nil }
            
            let pageRect = page.getBoxRect(.mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            
            let image = renderer.image { context in
                UIColor.white.set()
                context.fill(pageRect)
                
                context.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
                context.cgContext.scaleBy(x: 1.0, y: -1.0)
                
                context.cgContext.drawPDFPage(page)
            }
            
            return image
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            DispatchQueue.main.async {
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

#Preview {
    UploadOptionsView(selectedImage: .constant(nil), viewModel: MedicineViewModel())
} 