import Foundation

class OpenFDAClient {
    static let shared = OpenFDAClient()
    private init() {}
    
    func searchDrugs(query: String) async throws -> [Medicine] {
        // Map common medicine names to their alternatives
        let commonAlternatives = [
            "paracetamol": ["acetaminophen", "tylenol", "panadol"],
            "acetaminophen": ["paracetamol", "tylenol", "panadol"]
        ]
        
        // Check if we need to search for alternatives
        let searchTerms = commonAlternatives[query.lowercased()] ?? [query]
        
        // Try each search term
        for searchTerm in searchTerms {
            let encodedQuery = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchTerm
            let urlString = "\(APIConfig.openFDABaseURL)/label.json?search=(openfda.brand_name:\"\(encodedQuery)\"+OR+openfda.generic_name:\"\(encodedQuery)\")&limit=10&api_key=\(APIConfig.openFDAKey)"
            
            guard let url = URL(string: urlString) else {
                continue
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data),
                   let error = errorResponse.error {
                    print("API Error for \(searchTerm): \(error.message)")
                    continue
                }
                
                let fdaResponse = try JSONDecoder().decode(OpenFDAResponse.self, from: data)
                if let results = fdaResponse.results, !results.isEmpty {
                    // Process results
                    var uniqueMedicines: [String: Medicine] = [:]
                    
                    for result in results {
                        guard let brandNames = result.openfda?.brand_name,
                              !brandNames.isEmpty else { continue }
                        
                        let matchingBrandName = brandNames.first { name in
                            name.lowercased() == query.lowercased() ||
                            name.lowercased().starts(with: query.lowercased())
                        } ?? brandNames.first ?? ""
                        
                        if matchingBrandName.isEmpty { continue }
                        
                        let key = matchingBrandName.lowercased()
                        if uniqueMedicines[key] != nil { continue }
                        
                        var alternatives: [String] = []
                        if let genericNames = result.openfda?.generic_name {
                            alternatives.append(contentsOf: genericNames)
                        }
                        alternatives.append(contentsOf: brandNames.filter { $0 != matchingBrandName })
                        
                        let description = result.indications_and_usage?.first?.components(separatedBy: ".").first ?? 
                                        result.purpose?.first?.components(separatedBy: ".").first ??
                                        result.description?.first?.components(separatedBy: ".").first ??
                                        "No description available"
                        
                        let dosage = extractDosageInformation(from: result.dosage_and_administration)
                        
                        let medicine = Medicine(
                            name: matchingBrandName,
                            description: description,
                            alternatives: Array(Set(alternatives)).filter { !$0.isEmpty },
                            dosage: dosage,
                            warnings: result.warnings ?? ["Please consult your healthcare provider"],
                            requiresPrescription: result.openfda?.product_type?.contains("PRESCRIPTION") ?? true,
                            sideEffects: extractSideEffects(from: result.adverse_reactions),
                            usageInstructions: result.dosage_and_administration?.first ?? "Take as directed by your healthcare provider"
                        )
                        uniqueMedicines[key] = medicine
                    }
                    
                    if !uniqueMedicines.isEmpty {
                        return Array(uniqueMedicines.values)
                    }
                }
            } catch {
                print("Search error for \(searchTerm): \(error.localizedDescription)")
                continue
            }
        }
        
        // If no results found, try alternative search
        return try await searchWithAlternativeQuery(query)
    }
    
    private func extractDosageInformation(from dosageArray: [String]?) -> String {
        guard let dosageText = dosageArray?.first else {
            return "Consult your healthcare provider"
        }
        
        // Try to find simple, clear dosage instructions first
        let simplePatterns = [
            "take one tablet",
            "take 1 tablet",
            "take two tablets",
            "take 2 tablets",
            "one capsule",
            "1 capsule",
            "two capsules",
            "2 capsules",
            "mg every",
            "tablet every",
            "capsule every"
        ]
        
        let sentences = dosageText.components(separatedBy: ".")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Look for simple dosage instructions
        for sentence in sentences {
            let lowercased = sentence.lowercased()
            
            // If we find a simple, clear instruction, return it
            if simplePatterns.first(where: { lowercased.contains($0) }) != nil {
                if lowercased.contains("every") || 
                   lowercased.contains("times") || 
                   lowercased.contains("daily") ||
                   lowercased.contains("hours") {
                    return sentence + "."
                }
            }
        }
        
        // If no simple instruction found, look for any complete dosage information
        for sentence in sentences {
            let lowercased = sentence.lowercased()
            if (lowercased.contains("take") || lowercased.contains("recommended")) &&
               (lowercased.contains("mg") || lowercased.contains("tablet") || lowercased.contains("capsule")) {
                // Clean up the sentence
                let cleaned = sentence
                    .replacingOccurrences(of: "  ", with: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if cleaned.count < 100 { // Keep it reasonably sized
                    return cleaned + "."
                }
            }
        }
        
        // If still no clear dosage found, look for any dosage-related information
        for sentence in sentences {
            let lowercased = sentence.lowercased()
            if lowercased.contains("mg") || 
               lowercased.contains("tablet") || 
               lowercased.contains("capsule") {
                let cleaned = sentence
                    .replacingOccurrences(of: "  ", with: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if cleaned.count < 100 {
                    return cleaned + "."
                }
            }
        }
        
        return "Consult your healthcare provider for dosage information"
    }
    
    private func extractSideEffects(from reactionsArray: [String]?) -> [String] {
        guard let reactionsText = reactionsArray?.first else {
            return ["Consult healthcare provider for side effects"]
        }
        
        // Common side effects keywords to look for
        let sideEffectKeywords = [
            "headache",
            "nausea",
            "dizziness",
            "drowsiness",
            "vomiting",
            "diarrhea",
            "pain",
            "rash",
            "fatigue",
            "stomach"
        ]
        
        // Split the text and clean up
        let effects = reactionsText
            .components(separatedBy: CharacterSet(charactersIn: ".,;"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Filter out common introductory phrases and keep only relevant effects
        let relevantEffects = effects.filter { effect in
            let lowercased = effect.lowercased()
            return !lowercased.contains("following") &&
                   !lowercased.contains("include") &&
                   !lowercased.contains("including") &&
                   !lowercased.contains("such as") &&
                   !lowercased.contains("may") &&
                   !lowercased.contains("can") &&
                   !lowercased.starts(with: "the") &&
                   !lowercased.starts(with: "these") &&
                   sideEffectKeywords.contains { lowercased.contains($0) }
        }
        
        // Take the first 3-5 most relevant side effects
        let cleanedEffects = relevantEffects
            .prefix(4)
            .map { effect -> String in
                let cleaned = effect.trimmingCharacters(in: .whitespacesAndNewlines)
                return cleaned.first?.isUppercase == true ? cleaned : cleaned.capitalized
            }
        
        return cleanedEffects.isEmpty ? ["Consult healthcare provider for side effects"] : cleanedEffects
    }
    
    private func searchWithAlternativeQuery(_ query: String) async throws -> [Medicine] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(APIConfig.openFDABaseURL)/label.json?search=openfda.generic_name:\"\(encodedQuery)\"+OR+openfda.brand_name:\"\(encodedQuery)\"&limit=20&api_key=\(APIConfig.openFDAKey)"
        
        guard let url = URL(string: urlString) else {
            return [createFallbackMedicine(for: query)]
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let fdaResponse = try JSONDecoder().decode(OpenFDAResponse.self, from: data)
            
            if let results = fdaResponse.results {
                let matchingResult = results.first { result in
                    if let brandNames = result.openfda?.brand_name {
                        return brandNames.contains { $0.lowercased().contains(query.lowercased()) }
                    }
                    if let genericNames = result.openfda?.generic_name {
                        return genericNames.contains { $0.lowercased().contains(query.lowercased()) }
                    }
                    return false
                } ?? results.first
                
                if let result = matchingResult,
                   let brandName = result.openfda?.brand_name?.first {
                    var alternatives: [String] = []
                    if let genericNames = result.openfda?.generic_name {
                        alternatives.append(contentsOf: genericNames)
                    }
                    if let brandNames = result.openfda?.brand_name {
                        alternatives.append(contentsOf: brandNames.filter { $0 != brandName })
                    }
                    
                    let dosage = extractDosageInformation(from: result.dosage_and_administration)
                    
                    return [Medicine(
                        name: brandName,
                        description: result.indications_and_usage?.first?.components(separatedBy: ".").first ?? "No description available",
                        alternatives: Array(Set(alternatives)).filter { !$0.isEmpty },
                        dosage: dosage,
                        warnings: result.warnings ?? ["Please consult your healthcare provider"],
                        requiresPrescription: result.openfda?.product_type?.contains("PRESCRIPTION") ?? true,
                        sideEffects: extractSideEffects(from: result.adverse_reactions),
                        usageInstructions: "Take as directed by your healthcare provider"
                    )]
                }
            }
        } catch {
            print("Alternative search error: \(error.localizedDescription)")
        }
        
        return [createFallbackMedicine(for: query)]
    }
    
    private func createFallbackMedicine(for query: String) -> Medicine {
        return Medicine(
            name: query,
            description: "No detailed information available for this medication.",
            alternatives: [],
            dosage: "Consult your healthcare provider",
            warnings: ["Please consult your healthcare provider"],
            requiresPrescription: true,
            sideEffects: ["Consult healthcare provider"],
            usageInstructions: "Consult healthcare provider"
        )
    }
} 