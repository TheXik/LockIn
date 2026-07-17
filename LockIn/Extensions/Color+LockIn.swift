import SwiftUI

extension Color {
    // MARK: - Brand Colors — "Ember": warm, layered, glowing dark.
    // Every competitor ships cold/clinical dark. LockIn is a hearth you keep lit
    // with your people. Nothing here is pure #000 or pure #FFF — the warmth is
    // the differentiator. Token NAMES are stable (33 files depend on them);
    // only the values evolved.

    // Accent — the ember system
    static let lockInPrimary = Color(hex: "FFD60A")       // brand yellow — the signal, unchanged
    static let lockInSecondary = Color(hex: "FF8A34")     // ember orange — warmer than before
    static let lockInEmber = Color(hex: "FF5E1F")         // deep ember — gradient tail
    static let lockInGlow = Color(hex: "FFB020")          // the glow material

    // Backgrounds — warm near-black, layered for real depth
    static let lockInBackground = Color(hex: "0B0A09")    // warm near-black base
    static let lockInSurface = Color(hex: "17140F")       // card
    static let lockInSurfaceLight = Color(hex: "211C14")  // elevated
    static let lockInSurfaceHi = Color(hex: "2C2519")     // pressed / highest

    // Text — warm off-white, warm grays (not the cold system grays)
    static let lockInText = Color(hex: "F7F4ED")          // warm off-white
    static let lockInTextSecondary = Color(hex: "ABA398") // warm gray
    static let lockInTextTertiary = Color(hex: "8A8175")  // warm dim — lifted for WCAG AA (~4.8:1)

    // Semantic — warmed to sit in the ember world
    static let lockInSuccess = Color(hex: "34D373")       // green
    static let lockInWarning = Color(hex: "FFB020")       // amber
    static let lockInDanger = Color(hex: "FF5A47")        // warm red

    // Hairline — warm, not a cold white line
    static let lockInHairline = Color(hex: "FFE8C2").opacity(0.08)

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
