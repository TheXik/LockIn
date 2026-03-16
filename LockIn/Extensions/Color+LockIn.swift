import SwiftUI

extension Color {
    // MARK: - Brand Colors
    static let lockInPrimary = Color(hex: "6C5CE7")     // Deep purple
    static let lockInSecondary = Color(hex: "A29BFE")   // Light purple
    static let lockInAccent = Color(hex: "00D2FF")      // Cyan accent
    static let lockInBackground = Color(hex: "0F0F1A")  // Dark navy
    static let lockInSurface = Color(hex: "1A1A2E")     // Card surface
    static let lockInSurfaceLight = Color(hex: "25253D") // Elevated surface
    static let lockInSuccess = Color(hex: "00E676")     // Green
    static let lockInWarning = Color(hex: "FFD600")     // Yellow
    static let lockInDanger = Color(hex: "FF5252")      // Red
    static let lockInText = Color.white
    static let lockInTextSecondary = Color(hex: "A0A0B8")

    // MARK: - Hex Init
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
