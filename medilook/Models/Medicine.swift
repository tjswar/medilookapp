import Foundation

struct Medicine: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let name: String
    let description: String
    var alternatives: [String]
    let rxcui: String
    let dosage: String
    let warnings: [String]
    let requiresPrescription: Bool
    let sideEffects: [String]
    let usageInstructions: String
    
    init(
        name: String,
        description: String,
        alternatives: [String],
        rxcui: String = "",
        dosage: String = "",
        warnings: [String] = [],
        requiresPrescription: Bool = false,
        sideEffects: [String] = [],
        usageInstructions: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.alternatives = alternatives
        self.rxcui = rxcui
        self.dosage = dosage
        self.warnings = warnings
        self.requiresPrescription = requiresPrescription
        self.sideEffects = sideEffects
        self.usageInstructions = usageInstructions
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(rxcui)
    }
    
    static func == (lhs: Medicine, rhs: Medicine) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.description == rhs.description &&
        lhs.alternatives == rhs.alternatives &&
        lhs.rxcui == rhs.rxcui &&
        lhs.dosage == rhs.dosage &&
        lhs.warnings == rhs.warnings &&
        lhs.requiresPrescription == rhs.requiresPrescription &&
        lhs.sideEffects == rhs.sideEffects &&
        lhs.usageInstructions == rhs.usageInstructions
    }
} 