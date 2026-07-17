import SwiftUI
import FamilyControls

struct LockSetupView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var screenTimeAuth: ScreenTimeAuthService
    @EnvironmentObject var shieldManager: ShieldManager
    @EnvironmentObject var pactService: PactService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                VStack(alignment: .leading, spacing: LKSpace.lg) {
                    // Editorial hero — the decision, not a settings header
                    hero
                        .padding(.bottom, LKSpace.sm)

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
                        commitSection
                    }

                    // Deactivate
                    if shieldManager.isLockActive {
                        LockInButton("Remove Lock", icon: "lock.open.fill", style: .danger) {
                            shieldManager.deactivateShield(userId: authService.currentUser?.id)
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
            .navigationBarTitleDisplayMode(.inline)
            .lockInScreenBackground()
            .toolbarColorScheme(.dark, for: .navigationBar)
            .familyActivityPicker(
                isPresented: $showActivityPicker,
                selection: $shieldManager.selectedApps
            )
            .alert("Locked in", isPresented: $showConfirmation) {
                Button("Let's go") {}
            } message: {
                Text("Your apps are locked. Only your pact members can approve unlocks. Stay focused.")
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

    // MARK: - Hero
    private var hero: some View {
        VStack(alignment: .leading, spacing: LKSpace.sm) {
            Text("LOCK IN")
                .font(.lkMicro)
                .tracking(2)
                .foregroundColor(.lockInTextTertiary)

            (
                Text("Choose what\n")
                    .foregroundColor(.lockInText)
                + Text("owns you.")
                    .foregroundColor(.lockInPrimary)
            )
            .font(.system(size: 40, weight: .black))
            .tracking(-1.2)
            .lineSpacing(-2)
            .fixedSize(horizontal: false, vertical: true)
            .minimumScaleFactor(0.7)

            Text("Pick them. Commit. The only way back in is to ask your pact.")
                .font(.lkCallout)
                .foregroundColor(.lockInTextSecondary)
                .lineSpacing(2)
                .frame(maxWidth: 300, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - How It Works (editorial, type-led — no icon-square rows)
    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: LKSpace.lg) {
            Text("HOW IT WORKS")
                .font(.lkMicro)
                .tracking(2)
                .foregroundColor(.lockInTextTertiary)

            VStack(alignment: .leading, spacing: LKSpace.lg) {
                howStep("01", "Pick the apps that own you.")
                howStep("02", "Lock in. They vanish behind the shield.")
                howStep("03", "Want one back? Your pact decides — not you.")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lockInCard()
    }

    private func howStep(_ num: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: LKSpace.md) {
            Text(num)
                .font(.lkMono(16, .heavy))
                .foregroundColor(.lockInPrimary)
                .frame(width: 26, alignment: .leading)
            Text(text)
                .font(.lkBody)
                .foregroundColor(.lockInText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Permission
    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: LKSpace.md) {
            Text("FIRST, A KEY")
                .font(.lkMicro)
                .tracking(2)
                .foregroundColor(.lockInTextTertiary)

            Text("Grant Screen Time")
                .font(.lkTitle)
                .foregroundColor(.lockInText)

            Text("LockIn uses Apple's Screen Time to hold your apps shut. Your Screen Time data never leaves this device.")
                .font(.lkCallout)
                .foregroundColor(.lockInTextSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            LockInButton("Allow Access", icon: "checkmark.shield") {
                Task { await screenTimeAuth.requestAuthorization() }
            }
            .padding(.top, LKSpace.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lockInCard()
    }

    private var deniedCard: some View {
        VStack(alignment: .leading, spacing: LKSpace.sm) {
            HStack(spacing: LKSpace.sm) {
                Image(systemName: "xmark.octagon.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.lockInDanger)
                Text("Access denied")
                    .font(.lkBodyStrong)
                    .foregroundColor(.lockInText)
            }
            Text("Open Settings → Screen Time to let LockIn back in.")
                .font(.lkCallout)
                .foregroundColor(.lockInTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lockInCard()
        .overlay(
            RoundedRectangle(cornerRadius: LKRadius.lg, style: .continuous)
                .stroke(Color.lockInDanger.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Active Lock (the one lit element on this screen)
    private var activeLockBanner: some View {
        let count = shieldManager.selectedApps.applicationTokens.count
        return VStack(alignment: .leading, spacing: LKSpace.sm) {
            HStack(spacing: LKSpace.sm) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(LockInGradient.ember)
                    .lockInGlow(.lockInGlow, radius: 12, intensity: 0.6)
                Text("YOU'RE LOCKED IN")
                    .font(.lkMicro)
                    .tracking(2)
                    .foregroundColor(.lockInPrimary)
            }

            HStack(alignment: .firstTextBaseline, spacing: LKSpace.sm) {
                Text("\(count)")
                    .font(.lkMono(34, .heavy))
                    .foregroundColor(.lockInText)
                Text(count == 1 ? "app held" : "apps held")
                    .font(.lkCallout)
                    .foregroundColor(.lockInTextSecondary)
                if let duration = shieldManager.lockDurationFormatted {
                    Text("· \(duration)")
                        .font(.lkMono(15, .semibold))
                        .foregroundColor(.lockInPrimary)
                }
            }

            Text("Only your pact can let you out.")
                .font(.lkCaption)
                .foregroundColor(.lockInTextTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lockInCard()
        .overlay(
            RoundedRectangle(cornerRadius: LKRadius.lg, style: .continuous)
                .stroke(Color.lockInPrimary.opacity(0.28), lineWidth: 1)
        )
    }

    // MARK: - App Selection
    private var appSelectionSection: some View {
        let count = shieldManager.selectedApps.applicationTokens.count +
                    shieldManager.selectedApps.categoryTokens.count

        return VStack(alignment: .leading, spacing: LKSpace.lg) {
            HStack {
                Text("APPS TO LOCK")
                    .font(.lkMicro)
                    .tracking(2)
                    .foregroundColor(.lockInTextTertiary)
                Spacer()
                if !shieldManager.selectedApps.applicationTokens.isEmpty {
                    Button("Clear") {
                        shieldManager.selectedApps = FamilyActivitySelection()
                    }
                    .font(.lkCaption)
                    .foregroundColor(.lockInDanger)
                }
            }

            if count > 0 {
                HStack(alignment: .firstTextBaseline, spacing: LKSpace.sm) {
                    Text("\(count)")
                        .font(.lkMono(28, .heavy))
                        .foregroundColor(.lockInPrimary)
                    Text(count == 1 ? "app in the vault" : "apps in the vault")
                        .font(.lkCallout)
                        .foregroundColor(.lockInTextSecondary)
                    Spacer()
                }

                AppIconGrid(appTokens: shieldManager.selectedApps.applicationTokens)
            } else {
                // Empty state with a real line of voice
                VStack(alignment: .leading, spacing: LKSpace.xs) {
                    Text("The vault is empty.")
                        .font(.lkBodyStrong)
                        .foregroundColor(.lockInText)
                    Text("An empty vault changes nothing. Pick what's been running your day.")
                        .font(.lkCallout)
                        .foregroundColor(.lockInTextTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, LKSpace.xs)
            }

            LockInButton(
                count > 0 ? "Change Selection" : "Choose Apps to Lock",
                icon: "square.grid.2x2.fill",
                style: count > 0 ? .secondary : .primary
            ) {
                showActivityPicker = true
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lockInCard()
    }

    // MARK: - Schedule
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: LKSpace.md) {
            Text("SCHEDULE")
                .font(.lkMicro)
                .tracking(2)
                .foregroundColor(.lockInTextTertiary)

            ForEach(ScheduleOption.allCases, id: \.self) { option in
                let isSelected = selectedSchedule == option
                Button {
                    withAnimation(reduceMotion ? nil : .lkSnappy) {
                        selectedSchedule = option
                    }
                } label: {
                    HStack(spacing: LKSpace.md) {
                        Image(systemName: option.icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(isSelected ? .lockInPrimary : .lockInTextSecondary)
                            .frame(width: 22)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.rawValue)
                                .font(.lkBodyStrong)
                                .foregroundColor(.lockInText)
                            Text(option.subtitle)
                                .font(.lkCaption)
                                .foregroundColor(.lockInTextSecondary)
                        }
                        Spacer()
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? .lockInPrimary : .lockInTextTertiary)
                    }
                    .padding(LKSpace.lg)
                    .background(isSelected ? Color.lockInPrimary.opacity(0.08) : Color.lockInSurfaceLight)
                    .clipShape(RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous)
                            .stroke(
                                isSelected ? Color.lockInPrimary.opacity(0.25) : Color.clear,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lockInCard()
    }

    // MARK: - Daily Limit
    private var dailyLimitSection: some View {
        VStack(alignment: .leading, spacing: LKSpace.md) {
            HStack(alignment: .firstTextBaseline) {
                Text("DAILY LIMIT")
                    .font(.lkMicro)
                    .tracking(2)
                    .foregroundColor(.lockInTextTertiary)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(Int(dailyLimit))")
                        .font(.lkMono(30, .heavy))
                        .foregroundColor(.lockInPrimary)
                    Text("min")
                        .font(.lkCaption)
                        .foregroundColor(.lockInTextSecondary)
                }
            }

            Text("Want more time? Request it from your squad.")
                .font(.lkCaption)
                .foregroundColor(.lockInTextSecondary)

            Slider(value: $dailyLimit, in: 5...120, step: 5)
                .tint(.lockInPrimary)

            HStack {
                Text("5 min").font(.lkMicro).foregroundColor(.lockInTextTertiary)
                Spacer()
                Text("2 hours").font(.lkMicro).foregroundColor(.lockInTextTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lockInCard()
    }

    // MARK: - Commit
    private var commitSection: some View {
        VStack(alignment: .leading, spacing: LKSpace.md) {
            Text("No takebacks. Once you lock in, only your pact opens the door.")
                .font(.lkCaption)
                .foregroundColor(.lockInTextTertiary)
                .fixedSize(horizontal: false, vertical: true)

            LockInButton("Lock In", icon: "flame.fill") {
                Task { await activateLock() }
            }
        }
    }

    // MARK: - No Pact Warning
    private var noPactWarning: some View {
        HStack(spacing: LKSpace.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.lockInWarning)
            VStack(alignment: .leading, spacing: LKSpace.xs) {
                Text("No pact yet")
                    .font(.lkBodyStrong)
                    .foregroundColor(.lockInText)
                Text("You need an accountability partner before you can lock apps.")
                    .font(.lkCaption)
                    .foregroundColor(.lockInTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lockInCard()
        .overlay(
            RoundedRectangle(cornerRadius: LKRadius.lg, style: .continuous)
                .stroke(Color.lockInWarning.opacity(0.22), lineWidth: 1)
        )
    }

    // MARK: - Lock-In Celebration
    private var lockInCelebration: some View {
        ZStack {
            Color.lockInBackground.opacity(0.92).ignoresSafeArea()

            VStack(spacing: LKSpace.lg) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 72, weight: .black))
                    .foregroundStyle(LockInGradient.ember)
                    .lockInGlow(.lockInGlow, radius: 28, intensity: 0.7)

                Text("LOCKED IN")
                    .font(.system(size: 30, weight: .black))
                    .tracking(6)
                    .foregroundColor(.lockInText)

                Text("The door's shut. Go do the thing.")
                    .font(.lkCallout)
                    .foregroundColor(.lockInTextSecondary)
            }
            .scaleEffect(reduceMotion ? 1 : (showLockAnimation ? 1 : 0.5))
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
            #if DEBUG
            print("Failed to persist lock session: \(error)")
            #endif
            errorMessage = "Couldn't save lock session to server, but your apps are still blocked locally."
        }

        // Activate shields locally
        shieldManager.activateShield()

        // Celebration haptic + animation
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        withAnimation(reduceMotion ? nil : .lkBounce) {
            showLockAnimation = true
        }

        // Dismiss celebration after 1.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(reduceMotion ? nil : .lkSmooth) {
                showLockAnimation = false
            }
            showConfirmation = true
        }
    }
}
