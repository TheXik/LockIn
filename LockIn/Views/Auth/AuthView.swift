import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showContent = false
    @State private var currentTagline = 0

    private let taglines = [
        "Your friend has the key.",
        "Lock apps. Build streaks.",
        "Accountability, together.",
    ]

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────
            Color.black.ignoresSafeArea()

            // Warm radial glow — subtle, centered higher
            RadialGradient(
                colors: [
                    Color.lockInPrimary.opacity(0.07),
                    Color.lockInSecondary.opacity(0.03),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.3),
                startRadius: 30,
                endRadius: 350
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // ── Logo + tagline ──────────────────────
                VStack(spacing: 28) {
                    // Social visual — two emojis connected
                    HStack(spacing: 0) {
                        EmojiOrb(emoji: "🔥", color: .lockInPrimary)
                        ConnectionLine()
                        EmojiOrb(emoji: "💪", color: .lockInSecondary)
                    }
                    .scaleEffect(showContent ? 1 : 0.5)
                    .opacity(showContent ? 1 : 0)

                    VStack(spacing: 10) {
                        Text("LockIn")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundColor(.white)

                        Text(taglines[currentTagline])
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.lockInTextSecondary)
                            .contentTransition(.opacity)
                            .animation(.easeInOut(duration: 0.5), value: currentTagline)
                    }
                    .opacity(showContent ? 1 : 0)
                }

                Spacer()

                // ── How it works ────────────────────────
                VStack(spacing: 18) {
                    StepRow(num: "1", icon: "lock.fill", text: "Lock your distracting apps", color: .lockInPrimary)
                    StepRow(num: "2", icon: "person.2.fill", text: "Your friend approves unlocks", color: .lockInSecondary)
                    StepRow(num: "3", icon: "flame.fill", text: "Build your streak together", color: .lockInSuccess)
                }
                .padding(.horizontal, 32)
                .opacity(showContent ? 1 : 0)

                Spacer()

                // ── Sign in ─────────────────────────────
                VStack(spacing: 14) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task { await authService.handleAppleSignIn(result) }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 54)
                    .cornerRadius(16)
                    .shadow(color: .white.opacity(0.05), radius: 10, y: 4)

                    Text("No data leaves your device. Ever.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.lockInTextTertiary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.7).delay(0.15)) {
                showContent = true
            }
            // Rotate taglines every 3 seconds
            Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
                withAnimation {
                    currentTagline = (currentTagline + 1) % taglines.count
                }
            }
        }
    }
}

// MARK: - Supporting Views

private struct EmojiOrb: View {
    let emoji: String
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.08))
                .frame(width: 80, height: 80)

            Circle()
                .fill(color.opacity(0.04))
                .frame(width: 100, height: 100)

            Text(emoji)
                .font(.system(size: 36))
        }
    }
}

private struct ConnectionLine: View {
    var body: some View {
        ZStack {
            // Glow
            Rectangle()
                .fill(LockInGradient.primary)
                .frame(width: 36, height: 3)
                .blur(radius: 4)
                .opacity(0.5)

            // Solid line
            Rectangle()
                .fill(LockInGradient.primary)
                .frame(width: 36, height: 2)
        }
        .padding(.horizontal, -12) // Overlap into the orbs slightly
    }
}

private struct StepRow: View {
    let num: String
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            // Number badge
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }

            Text(text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.lockInText)

            Spacer()
        }
    }
}
