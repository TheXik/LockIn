import SwiftUI
import FamilyControls

struct LockSetupView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var screenTimeAuth: ScreenTimeAuthService
    @EnvironmentObject var shieldManager: ShieldManager
    @EnvironmentObject var pactService: PactService
    @State private var showActivityPicker = false
    @State private var selectedSchedule: ScheduleOption = .always
    @State private var dailyLimit: Double = 30
    @State private var showConfirmation = false
    @State private var isSaving = false
    @State private var showLockAnimation = false
    @State private var errorMessage: String?

    enum ScheduleOption: String, CaseIterable {
        case always = "Always"
        case workHours = "Work Hours (9-5)"
        case custom = "Custom"

        var icon: String {
            switch self {
            case .always: return "infinity"
            case .workHours: return "briefcase.fill"
            case .custom: return "calendar.badge.clock"
            }
        }

        var subtitle: String {
            switch self {
            case .always: return "Block 24/7 until you request an unlock"
            case .workHours: return "Block Monday–Friday, 9 AM – 5 PM"
            case .custom: return "Set your own schedule"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Screen Time permission
                    if case .notDetermined = screenTimeAuth.authorizationStatus {
                        permissionCard
                    } else if case .denied = screenTimeAuth.authorizationStatus {
                        deniedCard
                    }

                    // Active lock banner
                    if shieldManager.isLockActive {
                        activeLockBanner
                    }

                    // How it works (show only when no lock active and no apps selected)
                    if !shieldManager.isLockActive
                        && shieldManager.selectedApps.applicationTokens.isEmpty
                        && shieldManager.selectedApps.categoryTokens.isEmpty {
                        howItWorksCard
                    }

                    // App picker
                    appSelectionSection

                    // Schedule
                    scheduleSection

                    // Daily limit
                    dailyLimitSection

                    // Activate button
                    if !shieldManager.selectedApps.applicationTokens.isEmpty
                        && !pactService.myPacts.isEmpty
                        && !shieldManager.isLockActive {
                        LockInButton("Lock In 🔥") {
                            Task { await activateLock() }
                        }
                    }

                    // Deactivate
                    if shieldManager.isLockActive {
                        LockInButton("Remove Lock", icon: "lock.open.fill", style: .danger) {
                            shieldManager.deactivateShield()
                        }
                    }

                    if pactService.myPacts.isEmpty {
                        noPactWarning
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .navigationTitle("Lock Apps")
            .lockInScreenBackground()
            .toolbarColorScheme(.dark, for: .navigationBar)
            .familyActivityPicker(
                isPresented: $showActivityPicker,
                selection: $shieldManager.selectedApps
            )
            .alert("Locked In! 🔥", isPresented: $showConfirmation) {
                Button("Let's go") {}
            } message: {
                Text("Your apps are locked. Only your pact members can approve unlocks. Stay focused!")
            }
            .loadingOverlay(isSaving, message: "Locking in...")
            .errorBanner(errorMessage) { errorMessage = nil }
            .overlay {
                if showLockAnimation {
                    lockInCelebration
                }
            }
        }
    }

    // MARK: - How It Works (onboarding in context)
    private var howItWorksCard: some View {
        VStack(spacing: 18) {
            Text("HOW LOCKING WORKS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.lockInTextTertiary)
                .tracking(1.5)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 14) {
                HowItWorksStep(
                    num: 1,
                    icon: "plus.app.fill",
                    text: "Pick the apps you want to block",
                    color: .lockInPrimary
                )
                HowItWorksStep(
                    num: 2,
                    icon: "lock.fill",
                    text: "Hit \"Lock In\" — your apps are now blocked",
                    color: .lockInSecondary
                )
                HowItWorksStep(
                    num: 3,
                    icon: "person.2.fill",
                    text: "Need an app? Your pact members approve",
                    color: .lockInSuccess
                )
            }
        }
        .lockInCard()
    }

    // MARK: - Permission
    private var permissionCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.lockInPrimary.opacity(0.08))
                    .frame(width: 64, height: 64)

                Image(systemName: "hourglass")
                    .font(.system(size: 28))
                    .foregroundStyle(LockInGradient.primary)
            }

            VStack(spacing: 6) {
                Text("Screen Time access needed")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.lockInText)

                Text("LockIn uses Apple's Screen Time to block apps on your behalf. Your data stays on your device.")
                    .font(.system(size: 14))
                    .foregroundColor(.lockInTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            LockInButton("Allow Access", icon: "checkmark.shield") {
                Task { await screenTimeAuth.requestAuthorization() }
            }
        }
        .lockInCard()
    }

    private var deniedCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.lockInDanger)

            Text("Screen Time access denied")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.lockInText)

            Text("Go to Settings → Screen Time to enable access for LockIn.")
                .font(.system(size: 14))
                .foregroundColor(.lockInTextSecondary)
                .multilineTextAlignment(.center)
        }
        .lockInCard()
    }

    // MARK: - Active Lock
    private var activeLockBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.lockInPrimary.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: "flame.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(LockInGradient.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("You're locked in")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.lockInText)
                HStack(spacing: 4) {
                    Text("\(shieldManager.selectedApps.applicationTokens.count) apps blocked")
                    if let duration = shieldManager.lockDurationFormatted {
                        Text("· \(duration)")
                            .foregroundColor(.lockInPrimary)
                    }
                    Text("· Only your squad can unlock")
                }
                .font(.system(size: 13))
                .foregroundColor(.lockInTextSecondary)
            }
            Spacer()
        }
        .lockInCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.lockInPrimary.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - App Selection
    private var appSelectionSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("APPS TO LOCK")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.lockInTextTertiary)
                    .tracking(1.5)
                Spacer()
                if !shieldManager.selectedApps.applicationTokens.isEmpty {
                    Button("Clear") {
                        shieldManager.selectedApps = FamilyActivitySelection()
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.lockInDanger)
                }
            }

            let count = shieldManager.selectedApps.applicationTokens.count +
                        shieldManager.selectedApps.categoryTokens.count

            if count > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "app.badge.checkmark.fill")
                        .foregroundStyle(LockInGradient.primary)
                    Text("\(count) app\(count == 1 ? "" : "s") selected")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.lockInText)
                    Spacer()
                }

                AppIconGrid(appTokens: shieldManager.selectedApps.applicationTokens)
            } else {
                // Empty state
                VStack(spacing: 10) {
                    Image(systemName: "plus.app.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.lockInTextTertiary)
                    Text("No apps selected yet")
                        .font(.system(size: 14))
                        .foregroundColor(.lockInTextTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            LockInButton(
                count > 0 ? "Change Selection" : "Choose Apps to Lock",
                icon: "plus.app.fill",
                style: count > 0 ? .secondary : .primary
            ) {
                showActivityPicker = true
            }
        }
        .lockInCard()
    }

    // MARK: - Schedule
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SCHEDULE")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.lockInTextTertiary)
                .tracking(1.5)

            ForEach(ScheduleOption.allCases, id: \.self) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSchedule = option
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: option.icon)
                            .font(.system(size: 15))
                            .foregroundColor(selectedSchedule == option ? .lockInPrimary : .lockInTextSecondary)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.rawValue)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.lockInText)
                            Text(option.subtitle)
                                .font(.system(size: 12))
                                .foregroundColor(.lockInTextSecondary)
                        }
                        Spacer()
                        Image(systemName: selectedSchedule == option ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedSchedule == option ? .lockInPrimary : .lockInTextTertiary)
                            .font(.system(size: 20))
                    }
                    .padding(14)
                    .background(selectedSchedule == option ? Color.lockInPrimary.opacity(0.08) : Color.lockInSurfaceLight)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                selectedSchedule == option ? Color.lockInPrimary.opacity(0.2) : Color.clear,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .lockInCard()
    }

    // MARK: - Daily Limit
    private var dailyLimitSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("DAILY LIMIT")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.lockInTextTertiary)
                    .tracking(1.5)
                Spacer()
                Text("\(Int(dailyLimit)) min")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.lockInPrimary)
            }

            Text("Want more time? Request it from your squad.")
                .font(.system(size: 13))
                .foregroundColor(.lockInTextSecondary)

            Slider(value: $dailyLimit, in: 5...120, step: 5)
                .tint(.lockInPrimary)

            HStack {
                Text("5 min").font(.system(size: 11)).foregroundColor(.lockInTextTertiary)
                Spacer()
                Text("2 hours").font(.system(size: 11)).foregroundColor(.lockInTextTertiary)
            }
        }
        .lockInCard()
    }

    // MARK: - No Pact Warning
    private var noPactWarning: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.lockInWarning)
            VStack(alignment: .leading, spacing: 4) {
                Text("No pact yet")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.lockInText)
                Text("You need an accountability partner before you can lock apps.")
                    .font(.system(size: 13))
                    .foregroundColor(.lockInTextSecondary)
            }
        }
        .lockInCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.lockInWarning.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Lock-In Celebration
    private var lockInCelebration: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(LockInGradient.primary)
                    .shadow(color: .lockInPrimary.opacity(0.5), radius: 20)

                Text("LOCKED IN")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(4)

                Text("🔥")
                    .font(.system(size: 40))
            }
            .scaleEffect(showLockAnimation ? 1 : 0.5)
            .opacity(showLockAnimation ? 1 : 0)
        }
        .transition(.opacity)
    }

    // MARK: - Actions
    private func activateLock() async {
        guard let userId = authService.currentUser?.id,
              let pact = pactService.myPacts.first else { return }

        isSaving = true
        defer { isSaving = false }

        // Persist lock session to Supabase
        let appIds = shieldManager.selectedApps.applicationTokens.map { "\($0)" }

        struct LockSessionInsert: Encodable {
            let user_id: String
            let pact_id: String
            let app_identifiers: [String]
            let daily_limit_minutes: Int
            let is_active: Bool
        }

        let sessionData = LockSessionInsert(
            user_id: userId.uuidString,
            pact_id: pact.id.uuidString,
            app_identifiers: appIds,
            daily_limit_minutes: Int(dailyLimit),
            is_active: true
        )

        // Best effort persist
        do {
            try await supabase
                .from("lock_sessions")
                .insert(sessionData)
                .execute()
        } catch {
            print("Failed to persist lock session: \(error)")
            errorMessage = "Couldn't save lock session to server, but your apps are still blocked locally."
        }

        // Activate shields locally
        shieldManager.activateShield()

        // Celebration haptic + animation
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showLockAnimation = true
        }

        // Dismiss celebration after 1.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showLockAnimation = false
            }
            showConfirmation = true
        }
    }
}

// MARK: - How It Works Step

private struct HowItWorksStep: View {
    let num: Int
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.lockInText)

            Spacer()
        }
    }
}
