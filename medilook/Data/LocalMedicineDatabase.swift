import Foundation

extension MedicineViewModel {
    static let localDatabase: [Medicine] = [
        // ... (your existing medicines) ...
        Medicine(
            name: "Atorvastatin",
            description: "Cholesterol-lowering medication (statin).",
            alternatives: ["Lipitor", "Torvast"]
        ),
        Medicine(
            name: "Sertraline",
            description: "Antidepressant medication (SSRI).",
            alternatives: ["Zoloft", "Lustral", "Serlain"]
        ),
        // Add 20-30 more common medicines
    ]
} 