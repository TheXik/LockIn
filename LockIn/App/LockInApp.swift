import SwiftUI
import FamilyControls

@main
struct LockInApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authService = AuthService()
    @StateObject private var screenTimeAuth = ScreenTimeAuthService()
    @StateObject private var shieldManager = ShieldManager()
    @StateObject private var pactService = PactService()
    @StateObject private var unlockRequestService = UnlockRequestService()
    @StateObject private var pushService = PushNotificationService.shared
    @StateObject private var streakService = StreakService()

    @AppStorage(AppConstants.hasCompletedOnboardingKey) private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoading {
                    SplashView()
                } else if !authService.isAuthenticated {
                    AuthView()
                } else if !hasCompletedOnboarding {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                } else {
                    MainTabView()
                }
            }
            .preferredColorScheme(.dark)
            .environmentObject(authService)
            .environmentObject(screenTimeAuth)
            .environmentObject(shieldManager)
            .environmentObject(pactService)
            .environmentObject(unlockRequestService)
            .environmentObject(pushService)
            .environmentObject(streakService)
            .task {
                // Wire up sign-out cleanup
                authService.onSignOut = { [weak unlockRequestService, weak pactService, weak streakService] in
                    await unlockRequestService?.stopListening()
                    unlockRequestService?.reset()
                    pactService?.myPacts = []
                    pactService?.pactMembers = [:]
                    streakService?.currentStreak = 0
                    streakService?.longestStreak = 0
                    streakService?.totalLockDays = 0
                    streakService?.totalLocksThisWeek = 0
                }

                // Register for push when authenticated
                if authService.isAuthenticated {
                    _ = await pushService.requestPermission()
                }
                // Compute streak on launch
                if let userId = authService.currentUser?.id {
                    await streakService.computeStreak(userId: userId)
                }
            }
        }
    }
}

// MARK: - Splash Screen (animated brand intro)

struct SplashView: View {
    @State private var phase: SplashPhase = .initial

    enum SplashPhase {
        case initial, flameIn, textIn, glowPulse
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // ── Background glow ──────────────────────────
            ZStack {
                // Warm radial glow that pulses in
                RadialGradient(
                    colors: [
                        Color.lockInPrimary.opacity(phase == .glowPulse ? 0.12 : 0),
                        Color.lockInSecondary.opacity(phase == .glowPulse ? 0.04 : 0),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: 250
                )
                .ignoresSafeArea()

                // Subtle ring
                Circle()
                    .stroke(
                        Color.lockInPrimary.opacity(phase == .glowPulse ? 0.08 : 0),
                        lineWidth: 1
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(phase == .glowPulse ? 1.3 : 0.8)
            }
            .animation(.easeOut(duration: 1.5), value: phase)

            VStack(spacing: 24) {
                // ── Flame icon ────────────────────────────
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(Color.lockInPrimary.opacity(phase != .initial ? 0.06 : 0))
                        .frame(width: 120, height: 120)
                        .scaleEffect(phase == .glowPulse ? 1.1 : 0.9)

                    // Inner glow
                    Circle()
                        .fill(Color.lockInPrimary.opacity(phase != .initial ? 0.1 : 0))
                        .frame(width: 80, height: 80)

                    // The flame
                    Image(systemName: "flame.fill")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(LockInGradient.primary)
                        .scaleEffect(phase != .initial ? 1 : 0.3)
                        .opacity(phase != .initial ? 1 : 0)
                        .shadow(color: .lockInPrimary.opacity(0.4), radius: 16, y: 4)
                }

                // ── Brand text ────────────────────────────
                VStack(spacing: 8) {
                    Text("LockIn")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(phase == .textIn || phase == .glowPulse ? 1 : 0)
                        .offset(y: phase == .textIn || phase == .glowPulse ? 0 : 10)

                    Text("Accountability, together.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.lockInTextSecondary)
                        .opacity(phase == .glowPulse ? 1 : 0)
                        .offset(y: phase == .glowPulse ? 0 : 6)
                }

                // ── Loading dots ──────────────────────────
                if phase == .glowPulse {
                    LoadingDots()
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            // Staggered animation sequence
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                phase = .flameIn
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    phase = .textIn
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    phase = .glowPulse
                }
            }
        }
    }
}

// MARK: - Loading Dots (bouncing animation)

private struct LoadingDots: View {
    @State private var activeIndex = 0

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index == activeIndex ? Color.lockInPrimary : Color.lockInTextTertiary)
                    .frame(width: 6, height: 6)
                    .scaleEffect(index == activeIndex ? 1.3 : 1)
                    .animation(.easeInOut(duration: 0.35), value: activeIndex)
            }
        }
        .padding(.top, 16)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                activeIndex = (activeIndex + 1) % 3
            }
        }
    }
}
