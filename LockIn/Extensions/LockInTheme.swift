import SwiftUI

// The "Ember" design system: type, space, radius, motion, and the glow material.
// Additive layer — the color tokens live in Color+LockIn.swift.

// MARK: - Type
// SF Pro, one branded rounded wordmark, monospaced digits for codes/timers.
// Sizes are paired with .dynamicTypeSize clamping at call sites where overflow
// matters; the scale itself is a major-third-ish ramp.

extension Font {
    /// The wordmark only — friendly, rounded, heavy. Not for body.
    static func lkWordmark(_ size: CGFloat = 40) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }
    static let lkDisplay = Font.system(size: 34, weight: .bold)          // hero numbers, big statements
    static let lkTitle = Font.system(size: 24, weight: .bold)            // screen titles
    static let lkHeadline = Font.system(size: 18, weight: .semibold)     // section heads
    static let lkBody = Font.system(size: 16, weight: .regular)          // running text
    static let lkBodyStrong = Font.system(size: 16, weight: .semibold)
    static let lkCallout = Font.system(size: 15, weight: .medium)
    static let lkCaption = Font.system(size: 13, weight: .medium)
    static let lkMicro = Font.system(size: 11, weight: .semibold)
    /// Invite codes, timers, counts — tabular so digits don't jitter.
    static func lkMono(_ size: CGFloat = 20, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Spacing (4pt scale)

enum LKSpace {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

// MARK: - Radius

enum LKRadius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 18
    static let xl: CGFloat = 26
    static let pill: CGFloat = 999
}

// MARK: - Motion

extension Animation {
    static let lkSnappy = Animation.spring(response: 0.35, dampingFraction: 0.8)
    static let lkSmooth = Animation.spring(response: 0.55, dampingFraction: 0.85)
    static let lkBounce = Animation.spring(response: 0.5, dampingFraction: 0.65)
}

// MARK: - Gradients

extension LockInGradient {
    /// Full ember: yellow → orange → deep ember. The hero gradient.
    static let ember = LinearGradient(
        colors: [Color.lockInPrimary, Color.lockInSecondary, Color.lockInEmber],
        startPoint: .top,
        endPoint: .bottom
    )
    /// Warm screen wash — a hearth glow at the top of a dark screen.
    static let hearth = RadialGradient(
        colors: [Color.lockInGlow.opacity(0.10), Color.lockInEmber.opacity(0.03), .clear],
        center: .init(x: 0.5, y: 0.28),
        startRadius: 20,
        endRadius: 420
    )
}

// MARK: - The glow material

extension View {
    /// The flame-glow. Use on the one thing per screen that should feel lit.
    func lockInGlow(_ color: Color = .lockInGlow, radius: CGFloat = 24, intensity: Double = 0.5) -> some View {
        self
            .shadow(color: color.opacity(intensity), radius: radius)
            .shadow(color: color.opacity(intensity * 0.5), radius: radius * 2)
    }

    /// Warm hairline stroke, for cards and dividers.
    func lockInHairlineStroke(_ radius: CGFloat = LKRadius.lg) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(Color.lockInHairline, lineWidth: 1)
        )
    }
}
