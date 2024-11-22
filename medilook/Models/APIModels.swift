import Foundation

// OpenFDA API Response Models
struct OpenFDAResponse: Codable {
    let meta: Meta?
    let results: [DrugResult]?
    
    struct Meta: Codable {
        let disclaimer: String?
        let terms: String?
        let license: String?
        let lastUpdated: String?
        
        enum CodingKeys: String, CodingKey {
            case disclaimer
            case terms
            case license
            case lastUpdated = "last_updated"
        }
    }
}

struct DrugResult: Codable {
    let openfda: OpenFDA?
    let indications_and_usage: [String]?
    let purpose: [String]?
    let dosage_and_administration: [String]?
    let warnings: [String]?
    let description: [String]?
    let adverse_reactions: [String]?
}

struct OpenFDA: Codable {
    let brand_name: [String]?
    let generic_name: [String]?
    let substance_name: [String]?
    let manufacturer_name: [String]?
    let product_type: [String]?
    let route: [String]?
}

// Error Response Model
struct ErrorResponse: Codable {
    let error: APIError?
    
    struct APIError: Codable {
        let code: String
        let message: String
    }
} 