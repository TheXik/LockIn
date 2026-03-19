import SwiftUI

/// First-launch onboarding: explains the concept, requests Screen Time, push notifications.
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var screenTimeAuth: ScreenTimeAuthService
    @EnvironmentObject var pushService: PushNotificationService
    @State private var currentPage = 0

    private let totalPages = 4

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Page content ──────────────────────────
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    howItWorksPage.tag(1)
                    screenTimePage.tag(2)
                    notificationsPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: currentPage)

                // ── Page dots + button ───────────────────
                VStack(spacing: 24) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? Color.lockInPrimary : Color.lockInTextTertiary.opacity(0.3))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }

                    // Action button
                    Button {
                        handleAction()
                    } label: {
                        Text(buttonTitle)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.lockInPrimary)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)

                    // Skip (only on permissions pages)
                    if currentPage >= 2 {
                        Button {
                            if currentPage < totalPages - 1 {
                                withAnimation { currentPage += 1 }
                            } else {
                                completeOnboarding()
                            }
                        } label: {
                            Text("Skip for now")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.lockInTextTertiary)
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated emoji pair
            HStack(spacing: 0) {
                OnboardingOrb(emoji: "🔥", color: .lockInPrimary)
                OnboardingConnectionLine()
                OnboardingOrb(emoji: "💪", color: .lockInSecondary)
            }

            VStack(spacing: 12) {
                Text("Your friend has\nthe key")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Lock your distracting apps.\nOnly your squad can unlock them.")
                    .font(.system(size: 16))
                    .foregroundColor(.lockInTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()
            Spacer()
        }
    }

    private var howItWorksPage: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                OnboardingFeature(
                    icon: "plus.app.fill",
                    color: .lockInPrimary,
                    title: "Pick apps to block",
                    subtitle: "Choose TikTok, Instagram, Twitter — whatever kills your focus"
                )

                OnboardingFeature(
                    icon: "person.2.fill",
                    color: .lockInSecondary,
                    title: "Form a pact",
                    subtitle: "Invite 1-3 friends. They hold you accountable (and you hold them)"
                )

                OnboardingFeature(
                    icon: "flame.fill",
                    color: .lockInSuccess,
                    title: "Build your streak",
                    subtitle: "Every day locked in adds to your streak. Break it? Your squad knows"
                )

                OnboardingFeature(
                    icon: "lock.open.fill",
                    color: .lockInWarning,
                    title: "Need an app? Ask.",
                    subtitle: "Send an unlock request. Your friend decides if it's worth it"
                )
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
    }

    private var screenTimePage: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.lockInPrimary.opacity(0.08))
                    .frame(width: 120, height: 120)

                Image(systemName: "hourglass")
                    .font(.system(size: 48))
                    .foregroundStyle(LockInGradient.primary)
            }

            VStack(spacing: 12) {
                Text("Enable Screen Time")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text("LockIn uses Apple's Screen Time API to block apps at the OS level. No VPN tricks — real blocking that can't be bypassed.")
                    .font(.system(size: 15))
                    .foregroundColor(.lockInTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
            }

            // Status badge
            HStack(spacing: 8) {
                Image(systemName: screenTimeStatusIcon)
                    .foregroundColor(screenTimeStatusColor)
                Text(screenTimeStatusText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(screenTimeStatusColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(screenTimeStatusColor.opacity(0.1))
            .cornerRadius(12)

            Spacer()
            Spacer()
        }
    }

    private var notificationsPage: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.lockInSecondary.opacity(0.08))
                    .frame(width: 120, height: 120)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(LockInGradient.primary)
            }

            VStack(spacing: 12) {
                Text("Stay in the loop")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text("Get notified when your squad needs you to approve an unlock. Don't leave them hanging!")
                    .font(.system(size: 15))
                    .foregroundColor(.lockInTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
            }

            // Status badge
            HStack(spacing: 8) {
                Image(systemName: pushService.isPermissionGranted ? "checkmark.circle.fill" : "bell.slash")
                    .foregroundColor(pushService.isPermissionGranted ? .lockInSuccess : .lockInTextTertiary)
                Text(pushService.isPermissionGranted ? "Notifications enabled" : "Tap below to enable")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(pushService.isPermissionGranted ? .lockInSuccess : .lockInTextTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background((pushService.isPermissionGranted ? Color.lockInSuccess : Color.lockInTextTertiary).opacity(0.1))
            .cornerRadius(12)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Button Logic

    private var buttonTitle: String {
        switch currentPage {
        case 0: return "Let's go"
        case 1: return "Got it"
        case 2:
            if case .approved = screenTimeAuth.authorizationStatus {
                return "Continue"
            }
            return "Enable Screen Time"
        case 3:
            return pushService.isPermissionGranted ? "Start using LockIn" : "Enable Notifications"
        default: return "Continue"
        }
    }

    private func handleAction() {
        switch currentPage {
        case 0, 1:
            withAnimation { currentPage += 1 }

        case 2:
            if case .approved = screenTimeAuth.authorizationStatus {
                withAnimation { currentPage += 1 }
            } else {
                Task {
                    await screenTimeAuth.requestAuthorization()
                    // Auto-advance if granted
                    if case .approved = screenTimeAuth.authorizationStatus {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        withAnimation { currentPage += 1 }
                    }
                }
            }

        case 3:
            if pushService.isPermissionGranted {
                completeOnboarding()
            } else {
                Task {
                    let granted = await pushService.requestPermission()
                    if granted {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                    }
                    completeOnboarding()
                }
            }

        default:
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
    }

    // MARK: - Screen Time Status

    private var screenTimeStatusIcon: String {
        switch screenTimeAuth.authorizationStatus {
        case .approved: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        default: return "questionmark.circle"
        }
    }

    private var screenTimeStatusColor: Color {
        switch screenTimeAuth.authorizationStatus {
        case .approved: return .lockInSuccess
        case .denied: return .lockInDanger
        default: return .lockInTextTertiary
        }
    }

    private var screenTimeStatusText: String {
        switch screenTimeAuth.authorizationStatus {
        case .approved: return "Screen Time enabled"
        case .denied: return "Access denied — check Settings"
        default: return "Not enabled yet"
        }
    }
}

// MARK: - Supporting Components

private struct OnboardingOrb: View {
    let emoji: String
    let color: Color
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.06))
                .frame(width: 100, height: 100)
                .scaleEffect(isAnimating ? 1.1 : 0.95)

            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 72, height: 72)

            Text(emoji)
                .font(.system(size: 36))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

private struct OnboardingConnectionLine: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(LockInGradient.primary)
                .frame(width: 40, height: 3)
                .blur(radius: 4)
                .opacity(0.5)

            Rectangle()
                .fill(LockInGradient.primary)
                .frame(width: 40, height: 2)
        }
        .padding(.horizontal, -10)
    }
}

private struct OnboardingFeature: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.lockInText)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.lockInTextSecondary)
                    .lineSpacing(2)
            }

            Spacer()
        }
    }
}
