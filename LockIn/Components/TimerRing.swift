import SwiftUI

/// The centerpiece of the home screen — a focus ring with your squad orbiting it.
/// When active: pulsing flame, gradient ring, squad emojis with status dots.
/// When inactive: dimmed ring, prompt to lock in.
struct TimerRing: View {
    let isActive: Bool
    let lockedAppCount: Int
    var streakDays: Int = 0
    var squadMembers: [SquadMember] = []

    struct SquadMember: Identifiable {
        let id: UUID
        let emoji: String
        let name: String
        let isLockedIn: Bool
    }

    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @State private var ringRotation: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let ringSize: CGFloat = 200
    private let orbitRadius: CGFloat = 128

    var body: some View {
        ZStack {
            // ── Background glow ──────────────────────────
            if isActive {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.lockInPrimary.opacity(0.18),
                                Color.lockInSecondary.opacity(0.06),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 160
                        )
                    )
                    .frame(width: 300, height: 300)
                    .opacity(glowOpacity)
            }

            // ── Track ring ──────────────────────────────
            Circle()
                .stroke(
                    Color.lockInSurfaceLight,
                    style: StrokeStyle(lineWidth: isActive ? 6 : 4)
                )
                .frame(width: ringSize, height: ringSize)

            // ── Active gradient ring ─────────────────────
            if isActive {
                Circle()
                    .trim(from: 0, to: 1)
                    .stroke(
                        AngularGradient(
                            colors: [
                                .lockInPrimary,
                                .lockInSecondary,
                                .lockInPrimary.opacity(0.6),
                                .lockInPrimary
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(ringRotation - 90))
                    .lockInGlow(.lockInGlow, radius: 18, intensity: 0.45)
            }

            // ── Center content ──────────────────────────
            VStack(spacing: 4) {
                // Flame icon — grows slightly with streak
                let flameSize: CGFloat = isActive ? min(40 + CGFloat(streakDays) * 0.5, 52) : 32
                Image(systemName: isActive ? "flame.fill" : "flame")
                    .font(.system(size: flameSize, weight: .medium))
                    .foregroundStyle(
                        isActive
                            ? AnyShapeStyle(LockInGradient.primary)
                            : AnyShapeStyle(Color.lockInTextTertiary)
                    )
                    .scaleEffect(isActive ? pulseScale : 0.85)
                    .shadow(
                        color: isActive ? .lockInPrimary.opacity(0.5) : .clear,
                        radius: isActive ? 12 : 0
                    )

                if isActive {
                    Text("\(lockedAppCount)")
                        .font(.lkMono(38, .heavy))
                        .foregroundColor(.lockInText)
                        .contentTransition(.numericText())

                    Text("LOCKED IN")
                        .font(.lkMicro)
                        .foregroundColor(.lockInTextSecondary)
                        .tracking(3)
                } else {
                    Text("0")
                        .font(.lkMono(38, .heavy))
                        .foregroundColor(.lockInTextTertiary)

                    Text("READY")
                        .font(.lkMicro)
                        .foregroundColor(.lockInTextTertiary)
                        .tracking(3)
                }
            }

            // ── Orbiting squad members ──────────────────
            ForEach(Array(squadMembers.enumerated()), id: \.element.id) { index, member in
                let pos = memberPosition(index: index, total: squadMembers.count)
                SquadOrbitBubble(member: member, isActive: isActive)
                    .offset(x: pos.x, y: pos.y)
            }
        }
        .frame(height: 300)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isActive ? "\(lockedAppCount) apps locked, \(streakDays) day streak" : "Ready to lock in")
        .onAppear { startAnimations() }
        .onChange(of: isActive) { active in
            if active {
                startAnimations()
            } else {
                stopAnimations()
            }
        }
    }

    // MARK: - Orbit math

    private func memberPosition(index: Int, total: Int) -> CGPoint {
        guard total > 0 else { return .zero }
        // Distribute evenly, starting from top
        let angle = CGFloat(index) / CGFloat(total) * 2 * .pi - .pi / 2
        return CGPoint(
            x: Foundation.cos(angle) * orbitRadius,
            y: Foundation.sin(angle) * orbitRadius
        )
    }

    // MARK: - Animations

    private func startAnimations() {
        guard isActive else { return }
        guard !reduceMotion else { return }

        // Flame pulse
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            pulseScale = 1.08
        }

        // Glow pulse
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            glowOpacity = 0.6
        }

        // Slow ring rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
    }

    private func stopAnimations() {
        withAnimation(.easeOut(duration: 0.4)) {
            pulseScale = 1.0
            glowOpacity = 0.3
        }
    }
}

// MARK: - Squad Orbit Bubble

/// A pact member's emoji avatar that orbits the ring.
/// Green dot = locked in, gray dot = not.
private struct SquadOrbitBubble: View {
    let member: TimerRing.SquadMember
    let isActive: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottomTrailing) {
                // Emoji avatar
                Text(member.emoji)
                    .font(.system(size: 22))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(member.isLockedIn ? Color.lockInPrimary.opacity(0.15) : Color.lockInSurfaceLight)
                    )
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                member.isLockedIn ? Color.lockInPrimary.opacity(0.4) : Color.lockInHairline,
                                lineWidth: 2
                            )
                    )

                // Status dot
                Circle()
                    .fill(member.isLockedIn ? Color.lockInSuccess : Color.lockInTextTertiary)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color.lockInBackground, lineWidth: 2))
                    .offset(x: 2, y: 2)
            }

            // Name (first word only)
            Text(member.name.components(separatedBy: " ").first ?? "")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.lockInTextSecondary)
                .lineLimit(1)
        }
    }
}
