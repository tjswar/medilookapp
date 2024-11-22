import Foundation

struct SearchHistory: Identifiable, Codable {
    let id: UUID
    let query: String
    let timestamp: Date
    let results: [Medicine]
    
    init(query: String, results: [Medicine]) {
        self.id = UUID()
        self.query = query
        self.timestamp = Date()
        self.results = results
    }
}