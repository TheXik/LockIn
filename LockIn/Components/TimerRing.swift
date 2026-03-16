import SwiftUI

/// Circular countdown timer with animated ring.
struct TimerRing: View {
    let progress: Double       // 0.0 to 1.0
    let timeRemaining: String  // "23:45"
    let isActive: Bool

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.lockInSurface, lineWidth: 12)
                .frame(width: 220, height: 220)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [.lockInPrimary, .lockInAccent, .lockInPrimary],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            // Glow effect on the ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.lockInPrimary.opacity(0.4), lineWidth: 20)
                .blur(radius: 8)
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: 8) {
                Image(systemName: isActive ? "lock.fill" : "lock.open.fill")
                    .font(.system(size: 28))
                    .foregroundColor(isActive ? .lockInPrimary : .lockInTextSecondary)
                    .scaleEffect(pulseScale)

                Text(timeRemaining)
                    .font(.system(size: 42, weight: .bold, design: .monospaced))
                    .foregroundColor(.lockInText)

                Text(isActive ? "LOCKED IN" : "READY")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lockInTextSecondary)
                    .tracking(2)
            }
        }
        .onAppear {
            guard isActive else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        TimerRing(progress: 0.65, timeRemaining: "23:45", isActive: true)
        TimerRing(progress: 0, timeRemaining: "00:00", isActive: false)
    }
    .lockInGradientBackground()
}
