import SwiftUI

/// The full-screen cover shown while the user is locked in. Not a paywall, not a
/// scold — a warm confirmation that the pact is holding. The one lit element is the
/// lock itself. Editorial, left-aligned, type-led — matches AuthView's voice.
struct LockedMotivationView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var shieldManager: ShieldManager
    @EnvironmentObject var pactService: PactService

    /// Tapped "Request Unlock" — the only way back in is to ask the squad.
    var onRequestUnlock: () -> Void = {}
    /// Optional dismiss ("Stay focused") — hides the cover without unlocking.
    var onDismiss: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appear = false
    @State private var flamePulse = false

    private var lockedCount: Int { shieldManager.selectedApps.applicationTokens.count }

    /// First names of the pact members who can approve an unlock (excluding self).
    private var keyholders: [String] {
        guard let firstPact = pactService.myPacts.first else { return [] }
        let currentUserId = authService.currentUser?.id
        return pactService.members(for: firstPact.id)
            .filter { $0.userId != currentUserId }
            .compactMap { $0.profile?.displayName.components(separatedBy: " ").first }
    }

    var body: some View {
        ZStack {
            Color.lockInBackground.ignoresSafeArea()

            // Warm ember wash anchored low-left — same asymmetric hearth as AuthView.
            RadialGradient(
                colors: [Color.lockInEmber.opacity(0.20), Color.lockInGlow.opacity(0.06), .clear],
                center: .init(x: 0.18, y: 0.70),
                startRadius: 10,
                endRadius: 440
            )
            .ignoresSafeArea()
            .opacity(appear ? 1 : 0)

            LockedGrainOverlay().opacity(0.5).ignoresSafeArea().blendMode(.overlay)

            VStack(alignment: .leading, spacing: 0) {
                // ── Status label, top-left ──
                HStack(spacing: LKSpace.sm) {
                    Circle()
                        .fill(Color.lockInPrimary)
                        .frame(width: 7, height: 7)
                    Text("LOCKED IN")
                        .font(.lkMicro)
                        .tracking(2.5)
                        .foregroundColor(.lockInTextSecondary)
                }
                .padding(.top, LKSpace.sm)

                Spacer(minLength: LKSpace.xxl)

                // ── The lit lock — the one glowing element ──
                Image(systemName: "lock.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(LockInGradient.ember)
                    .lockInGlow(.lockInGlow, radius: 22, intensity: 0.55)
                    .scaleEffect(flamePulse ? 1.06 : 1.0)
                    .padding(.bottom, LKSpace.xl)

                // ── The statement is the hero ──
                (
                    Text("You're\n").foregroundColor(.lockInText)
                    + Text("locked in.").foregroundColor(.lockInPrimary)
                )
                .font(.system(size: 52, weight: .black))
                .tracking(-1.6)
                .lineSpacing(-4)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.7)
                .offset(x: appear ? 0 : -12)
                .opacity(appear ? 1 : 0)

                // ── Mono facts: apps + duration ──
                HStack(spacing: LKSpace.sm) {
                    Text("\(lockedCount) app\(lockedCount == 1 ? "" : "s")")
                        .font(.lkMono(15, .semibold))
                        .foregroundColor(.lockInText)
                    if let duration = shieldManager.lockDurationFormatted {
                        Text("·").foregroundColor(.lockInTextTertiary)
                        Text(duration)
                            .font(.lkMono(15, .semibold))
                            .foregroundColor(.lockInPrimary)
                    }
                }
                .padding(.top, LKSpace.lg)
                .opacity(appear ? 1 : 0)

                // ── The accountability line ──
                Text(keyholderLine)
                    .font(.lkBody)
                    .foregroundColor(.lockInTextSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 320, alignment: .leading)
                    .padding(.top, LKSpace.md)
                    .opacity(appear ? 1 : 0)

                Spacer()

                // ── Actions, anchored bottom ──
                VStack(alignment: .leading, spacing: LKSpace.md) {
                    LockInButton("Request Unlock", icon: "lock.open.fill", style: .secondary) {
                        onRequestUnlock()
                    }

                    if let onDismiss {
                        Button(action: onDismiss) {
                            Text("Stay focused")
                                .font(.lkCallout)
                                .foregroundColor(.lockInTextTertiary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, LKSpace.sm)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .opacity(appear ? 1 : 0)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.lkSmooth.delay(0.1)) { appear = true }
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                flamePulse = true
            }
        }
    }

    private var keyholderLine: String {
        switch keyholders.count {
        case 0:
            return "The only way back in is to ask. That was the whole point."
        case 1:
            return "The only way back in is to ask \(keyholders[0]) — and they'll tell you the truth."
        case 2:
            return "The only way back in is to ask \(keyholders[0]) or \(keyholders[1]). They hold the key."
        default:
            return "The only way back in is to ask your squad. They hold the key now."
        }
    }
}

// MARK: - Grain

/// Static film grain — same tactile treatment as AuthView, drawn once with a
/// deterministic seed so it doesn't re-shuffle on redraw.
private struct LockedGrainOverlay: View {
    var body: some View {
        Canvas { context, size in
            var seed: UInt64 = 88_172_645_463_325_252
            func rand() -> Double {
                seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17
                return Double(seed % 1000) / 1000.0
            }
            let count = Int(size.width * size.height / 90)
            for _ in 0..<count {
                let x = rand() * size.width
                let y = rand() * size.height
                let a = 0.02 + rand() * 0.05
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1.1, height: 1.1)),
                    with: .color(.white.opacity(a))
                )
            }
        }
        .allowsHitTesting(false)
    }
}
