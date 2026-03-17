import SwiftUI

/// Circular countdown ring — clean, minimal.
struct TimerRing: View {
    let progress: Double       // 0.0 to 1.0
    let timeRemaining: String  // "23:45"
    let isActive: Bool

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.lockInSurfaceLight, lineWidth: 8)
                .frame(width: 200, height: 200)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.lockInPrimary,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            // Center content
            VStack(spacing: 6) {
                Image(systemName: isActive ? "lock.fill" : "lock.open.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isActive ? .lockInPrimary : .lockInTextSecondary)
                    .scaleEffect(pulseScale)

                Text(timeRemaining)
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundColor(.lockInText)

                Text(isActive ? "LOCKED IN" : "READY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.lockInTextSecondary)
                    .tracking(3)
            }
        }
        .onAppear {
            guard isActive else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
}
