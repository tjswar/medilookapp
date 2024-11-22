import SwiftUI
import Foundation

@MainActor
class MedicineViewModel: ObservableObject {
    @Published var searchResults: [Medicine] = []
    @Published var searchHistory: [SearchHistory] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let openFDAClient = OpenFDAClient.shared
    
    init() {
        loadSearchHistory()
    }
    
    func searchMedicine(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let results = try await openFDAClient.searchDrugs(query: query)
                
                if !results.isEmpty {
                    self.searchResults = results
                    self.addToHistory(query: query, results: results)
                } else {
                    self.error = "No results found for '\(query)'"
                }
                self.isLoading = false
            } catch {
                self.error = "Error searching for medication: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func addToHistory(query: String, results: [Medicine]) {
        let historyItem = SearchHistory(query: query, results: results)
        searchHistory.removeAll { $0.query.lowercased() == query.lowercased() }
        searchHistory.insert(historyItem, at: 0)
        saveSearchHistory()
    }
    
    private func saveSearchHistory() {
        if searchHistory.count > 20 {
            searchHistory = Array(searchHistory.prefix(20))
        }
        
        if let encoded = try? JSONEncoder().encode(searchHistory) {
            UserDefaults.standard.set(encoded, forKey: "SearchHistory")
        }
    }
    
    private func loadSearchHistory() {
        if let data = UserDefaults.standard.data(forKey: "SearchHistory"),
           let decoded = try? JSONDecoder().decode([SearchHistory].self, from: data) {
            searchHistory = decoded
        }
    }
    
    func clearSearchHistory() {
        searchHistory.removeAll()
        UserDefaults.standard.removeObject(forKey: "SearchHistory")
    }
} 