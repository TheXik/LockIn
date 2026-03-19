import SwiftUI

extension Color {
    // MARK: - Brand Colors (Black/White/Yellow — BeReal × Duolingo vibe)
    static let lockInPrimary = Color(hex: "FFD60A")       // Bright yellow — brand accent
    static let lockInSecondary = Color(hex: "FF9F0A")     // Warm orange — secondary actions
    static let lockInBackground = Color(hex: "000000")    // OLED black
    static let lockInSurface = Color(hex: "141414")       // Card background
    static let lockInSurfaceLight = Color(hex: "1C1C1E")  // Elevated surface
    static let lockInSuccess = Color(hex: "30D158")       // Green
    static let lockInWarning = Color(hex: "FF9F0A")       // Orange — distinct from primary
    static let lockInDanger = Color(hex: "FF453A")        // Red
    static let lockInText = Color.white
    static let lockInTextSecondary = Color(hex: "8E8E93") // System gray
    static let lockInTextTertiary = Color(hex: "636366")  // Dimmer gray for hints

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
