import SwiftUI

// MARK: - Glow Effect
extension View {
    func glow(color: Color = .lockInPrimary, radius: CGFloat = 20) -> some View {
        self
            .shadow(color: color.opacity(0.6), radius: radius / 2)
            .shadow(color: color.opacity(0.3), radius: radius)
    }

    func lockInCard() -> some View {
        self
            .padding(20)
            .background(Color.lockInSurface)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.lockInPrimary.opacity(0.2), lineWidth: 1)
            )
    }

    func lockInGradientBackground() -> some View {
        self
            .background(
                LinearGradient(
                    colors: [Color.lockInBackground, Color.lockInSurface.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
    }
}

// MARK: - Animated Counter
struct AnimatedCounter: Animatable, View {
    var value: Double

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text("\(Int(value))")
            .font(.system(size: 64, weight: .bold, design: .rounded))
            .foregroundColor(.lockInText)
    }
}
