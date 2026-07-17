import SwiftUI

/// First-launch onboarding: explains the concept, requests Screen Time, push notifications.
/// "Ember" editorial treatment — each page is a left-aligned statement, not a centered carousel slide.
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var screenTimeAuth: ScreenTimeAuthService
    @EnvironmentObject var pushService: PushNotificationService
    @State private var currentPage = 0
    @State private var appear = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let totalPages = 4

    var body: some View {
        ZStack {
            Color.lockInBackground.ignoresSafeArea()

            // Warm ember wash, low-left — the hearth. Asymmetric on purpose.
            RadialGradient(
                colors: [Color.lockInEmber.opacity(0.20), Color.lockInGlow.opacity(0.05), .clear],
                center: .init(x: 0.14, y: 0.70),
                startRadius: 10,
                endRadius: 460
            )
            .ignoresSafeArea()
            .opacity(appear ? 1 : 0)

            GrainOverlay().opacity(0.5).ignoresSafeArea().blendMode(.overlay)

            VStack(spacing: 0) {
                // ── Page content ──────────────────────────
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    howItWorksPage.tag(1)
                    screenTimePage.tag(2)
                    notificationsPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .lkSmooth, value: currentPage)

                // ── Progress + button ────────────────────
                VStack(spacing: LKSpace.xl) {
                    // Progress bars — asymmetric, the active one stretched and lit
                    HStack(spacing: LKSpace.sm) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? Color.lockInPrimary : Color.lockInTextTertiary.opacity(0.25))
                                .frame(width: index == currentPage ? 26 : 8, height: 4)
                                .animation(reduceMotion ? nil : .lkSnappy, value: currentPage)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 28)

                    // Action button
                    Button {
                        handleAction()
                    } label: {
                        Text(buttonTitle)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.lockInBackground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.lockInPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 28)

                    // Skip (only on permissions pages)
                    if currentPage >= 2 {
                        Button {
                            if currentPage < totalPages - 1 {
                                withAnimation(reduceMotion ? nil : .lkSmooth) { currentPage += 1 }
                            } else {
                                completeOnboarding()
                            }
                        } label: {
                            Text("Skip for now")
                                .font(.lkCaption)
                                .foregroundColor(.lockInTextTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 44)
            }
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .lkSmooth.delay(0.05)) { appear = true }
        }
    }

    // MARK: - Shared header

    private func pageHeader(_ index: Int, glowFlame: Bool) -> some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LockInGradient.ember)
                    .lockInGlow(.lockInGlow, radius: glowFlame ? 10 : 0, intensity: glowFlame ? 0.5 : 0)
                Text("LockIn")
                    .font(.system(size: 17, weight: .heavy))
                    .tracking(-0.3)
                    .foregroundColor(.lockInText)
            }
            Spacer()
            Text(String(format: "%02d / %02d", index + 1, totalPages))
                .font(.lkMono(13, .semibold))
                .foregroundColor(.lockInTextTertiary)
        }
        .padding(.horizontal, 28)
        .padding(.top, 8)
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            pageHeader(0, glowFlame: true)

            Spacer(minLength: LKSpace.xxl)

            VStack(alignment: .leading, spacing: LKSpace.lg) {
                (
                    Text("Your friends\nhold the ")
                        .foregroundColor(.lockInText)
                    + Text("key.")
                        .foregroundColor(.lockInPrimary)
                )
                .font(.system(size: 48, weight: .black))
                .tracking(-1.4)
                .lineSpacing(-2)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.7)

                Text("Lock the apps that eat your day. The only way back in is to ask the people who’ll actually tell you no.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.lockInTextSecondary)
                    .lineSpacing(3)
                    .frame(maxWidth: 320, alignment: .leading)
            }
            .padding(.horizontal, 28)

            Spacer()
            Spacer()
        }
    }

    private var howItWorksPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            pageHeader(1, glowFlame: false)

            Spacer(minLength: LKSpace.xl)

            VStack(alignment: .leading, spacing: LKSpace.xxl) {
                (
                    Text("How it\n")
                        .foregroundColor(.lockInText)
                    + Text("works.")
                        .foregroundColor(.lockInPrimary)
                )
                .font(.system(size: 42, weight: .black))
                .tracking(-1.2)
                .lineSpacing(-2)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.7)

                VStack(alignment: .leading, spacing: LKSpace.xl) {
                    stepRow(1, "Pick your poison", "TikTok, Instagram, Twitter — whatever kills your focus.")
                    stepRow(2, "Form a pact", "Invite one to three friends. You hold each other to it.")
                    stepRow(3, "Keep the streak", "Every locked-in day counts. Break it and your squad sees.")
                    stepRow(4, "Need in? Ask.", "Send an unlock request. A friend decides if it’s worth it.")
                }
            }
            .padding(.horizontal, 28)

            Spacer()
        }
    }

    private func stepRow(_ n: Int, _ title: String, _ subtitle: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: LKSpace.lg) {
            Text(String(format: "%02d", n))
                .font(.lkMono(15, .bold))
                .foregroundColor(.lockInPrimary)
                .frame(width: 26, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.lkBodyStrong)
                    .foregroundColor(.lockInText)
                Text(subtitle)
                    .font(.lkCallout)
                    .foregroundColor(.lockInTextSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var screenTimePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            pageHeader(2, glowFlame: false)

            Spacer(minLength: LKSpace.xxl)

            // The one lit element on this screen — the lock.
            Image(systemName: "lock.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(LockInGradient.ember)
                .lockInGlow(.lockInGlow, radius: 18, intensity: 0.45)
                .padding(.horizontal, 28)
                .padding(.bottom, LKSpace.xl)

            VStack(alignment: .leading, spacing: LKSpace.lg) {
                (
                    Text("Real blocking.\n")
                        .foregroundColor(.lockInText)
                    + Text("No tricks.")
                        .foregroundColor(.lockInPrimary)
                )
                .font(.system(size: 40, weight: .black))
                .tracking(-1.2)
                .lineSpacing(-2)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.7)

                Text("LockIn uses Apple’s Screen Time to block apps at the OS level. No VPN hacks — real blocking that can’t be swiped away.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.lockInTextSecondary)
                    .lineSpacing(3)
                    .frame(maxWidth: 340, alignment: .leading)

                statusChip(
                    icon: screenTimeStatusIcon,
                    text: screenTimeStatusText,
                    color: screenTimeStatusColor
                )
                .padding(.top, LKSpace.xs)
            }
            .padding(.horizontal, 28)

            Spacer()
        }
    }

    private var notificationsPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            pageHeader(3, glowFlame: false)

            Spacer(minLength: LKSpace.xxl)

            // The one lit element on this screen — the bell.
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(LockInGradient.ember)
                .lockInGlow(.lockInGlow, radius: 18, intensity: 0.45)
                .padding(.horizontal, 28)
                .padding(.bottom, LKSpace.xl)

            VStack(alignment: .leading, spacing: LKSpace.lg) {
                (
                    Text("Don’t leave them\n")
                        .foregroundColor(.lockInText)
                    + Text("hanging.")
                        .foregroundColor(.lockInPrimary)
                )
                .font(.system(size: 40, weight: .black))
                .tracking(-1.2)
                .lineSpacing(-2)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.7)

                Text("A ping when your squad needs you to approve an unlock. Answer fast — someone’s counting on you.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.lockInTextSecondary)
                    .lineSpacing(3)
                    .frame(maxWidth: 340, alignment: .leading)

                statusChip(
                    icon: pushService.isPermissionGranted ? "checkmark.circle.fill" : "bell.slash",
                    text: pushService.isPermissionGranted ? "Notifications enabled" : "Tap below to enable",
                    color: pushService.isPermissionGranted ? .lockInSuccess : .lockInTextTertiary
                )
                .padding(.top, LKSpace.xs)
            }
            .padding(.horizontal, 28)

            Spacer()
        }
    }

    // MARK: - Status chip

    private func statusChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: LKSpace.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            Text(text)
                .font(.lkCallout)
                .foregroundColor(color)
        }
        .padding(.horizontal, LKSpace.lg)
        .padding(.vertical, LKSpace.md)
        .background(color.opacity(0.10))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }

    // MARK: - Button Logic

    private var buttonTitle: String {
        switch currentPage {
        case 0: return "Let’s go"
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
            withAnimation(reduceMotion ? nil : .lkSmooth) { currentPage += 1 }

        case 2:
            if case .approved = screenTimeAuth.authorizationStatus {
                withAnimation(reduceMotion ? nil : .lkSmooth) { currentPage += 1 }
            } else {
                Task {
                    await screenTimeAuth.requestAuthorization()
                    // Auto-advance if granted
                    if case .approved = screenTimeAuth.authorizationStatus {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        withAnimation(reduceMotion ? nil : .lkSmooth) { currentPage += 1 }
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

// MARK: - Grain

/// A static film grain, drawn once. Kills the flat-gradient look and gives the
/// dark a tactile, printed quality. Deterministic seed so it doesn't re-shuffle.
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
