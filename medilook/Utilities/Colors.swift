import SwiftUI

enum AppColors {
    // Main colors
    static let primary = Color(hex: "4158D0")
    static let secondary = Color(hex: "C850C0")
    static let background = Color.white
    
    // Text colors
    static let text = Color.black
    static let secondaryText = Color.gray
    
    // UI Elements
    static let cardBackground = Color.white
    static let searchBarBackground = Color.white.opacity(0.95)
    static let shadow = Color.black.opacity(0.05)
    
    // Status colors
    static let success = Color(hex: "34C759")
    static let warning = Color(hex: "FF9500")
    static let error = Color(hex: "FF3B30")
    
    // Gradients
    static let primaryGradient = LinearGradient(
        colors: [primary, secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [primary.opacity(0.1), .white],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Card shadow
    static let cardShadow = Shadow(color: shadow, radius: 5, x: 0, y: 2)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
} 