import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authService: AuthService
    @State private var appear = false

    var body: some View {
        ZStack {
            Color.lockInBackground.ignoresSafeArea()

            // Warm ember wash, anchored low-left — the version Lukáš picked. The
            // warmth is the whole point; asymmetric on purpose (centered = template).
            RadialGradient(
                colors: [Color.lockInEmber.opacity(0.22), Color.lockInGlow.opacity(0.06), .clear],
                center: .init(x: 0.14, y: 0.72),
                startRadius: 10,
                endRadius: 460
            )
            .ignoresSafeArea()
            .opacity(appear ? 1 : 0)

            GrainOverlay().opacity(0.5).ignoresSafeArea().blendMode(.overlay)

            VStack(alignment: .leading, spacing: 0) {
                // ── Wordmark, top-left — a logotype, not a centered hero ──
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(LockInGradient.ember)
                        .lockInGlow(.lockInGlow, radius: 10, intensity: 0.5)
                    Text("LockIn")
                        .font(.system(size: 19, weight: .heavy))
                        .tracking(-0.3)
                        .foregroundColor(.lockInText)
                }
                .padding(.top, 8)

                Spacer(minLength: LKSpace.xxl)

                // ── The statement IS the hero. Big, tight, left, editorial. ──
                VStack(alignment: .leading, spacing: LKSpace.lg) {
                    (
                        Text("Your friends\nhold the ")
                            .foregroundColor(.lockInText)
                        + Text("key.")
                            .foregroundColor(.lockInPrimary)
                    )
                    .font(.system(size: 52, weight: .black))
                    .tracking(-1.6)
                    .lineSpacing(-4)
                    .fixedSize(horizontal: false, vertical: true)
                    .offset(x: appear ? 0 : -12)
                    .opacity(appear ? 1 : 0)

                    Text("Lock the apps that own you. The only way back in is to ask the people who’ll actually tell you no.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.lockInTextSecondary)
                        .lineSpacing(3)
                        .frame(maxWidth: 320, alignment: .leading)
                        .opacity(appear ? 1 : 0)
                }

                Spacer()

                // ── Sign in — anchored bottom, full width ──
                VStack(alignment: .leading, spacing: LKSpace.md) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task { await authService.handleAppleSignIn(result) }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous))

                    // Legally load-bearing — must stay true. Only Screen Time data is
                    // device-only; profiles/pacts/tokens go to Supabase.
                    Text("Your Screen Time data stays on your device.")
                        .font(.lkCaption)
                        .foregroundColor(.lockInTextTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .opacity(appear ? 1 : 0)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.lkSmooth.delay(0.1)) { appear = true }
        }
    }
}

// MARK: - Grain

/// A static film grain, drawn once. Kills the "flat AI gradient" flatness and
/// gives the dark a tactile, printed quality. Deterministic seed so it doesn't
/// re-shuffle on redraw.
private struct GrainOverlay: View {
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
