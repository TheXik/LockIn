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

    enum ScheduleOption: String, CaseIterable {
        case always = "Always"
        case workHours = "Work Hours (9-5)"
        case custom = "Custom"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Screen Time permission
                    if case .notDetermined = screenTimeAuth.authorizationStatus {
                        permissionCard
                    }

                    // App picker
                    appSelectionSection

                    // Schedule
                    scheduleSection

                    // Daily limit
                    dailyLimitSection

                    // Activate
                    if !shieldManager.selectedApps.applicationTokens.isEmpty
                        && !pactService.myPacts.isEmpty {
                        LockInButton("Lock In 🔒") {
                            shieldManager.activateShield()
                            showConfirmation = true
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
            .alert("Locked In! 🔒", isPresented: $showConfirmation) {
                Button("OK") {}
            } message: {
                Text("Your apps are now locked. Only your pact members can approve unlocks.")
            }
        }
    }

    // MARK: - Permission
    private var permissionCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "hourglass")
                .font(.system(size: 32))
                .foregroundColor(.lockInPrimary)

            Text("Screen Time access needed")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.lockInText)

            Text("LockIn needs this to block apps on your behalf.")
                .font(.system(size: 14))
                .foregroundColor(.lockInTextSecondary)
                .multilineTextAlignment(.center)

            LockInButton("Allow Access", icon: "checkmark.shield") {
                Task { await screenTimeAuth.requestAuthorization() }
            }
        }
        .lockInCard()
    }

    // MARK: - App Selection
    private var appSelectionSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("APPS TO LOCK")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.lockInTextSecondary)
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
                HStack {
                    Text("\(count) apps selected")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.lockInText)
                    Spacer()
                }

                AppIconGrid(appTokens: shieldManager.selectedApps.applicationTokens)
            }

            LockInButton(
                count > 0 ? "Change Selection" : "Choose Apps",
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
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.lockInTextSecondary)
                .tracking(1.5)

            ForEach(ScheduleOption.allCases, id: \.self) { option in
                Button {
                    selectedSchedule = option
                } label: {
                    HStack {
                        Text(option.rawValue)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.lockInText)
                        Spacer()
                        Image(systemName: selectedSchedule == option ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedSchedule == option ? .lockInPrimary : .lockInTextSecondary)
                    }
                    .padding(14)
                    .background(selectedSchedule == option ? Color.lockInPrimary.opacity(0.1) : Color.lockInSurfaceLight)
                    .cornerRadius(12)
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
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.lockInTextSecondary)
                    .tracking(1.5)
                Spacer()
                Text("\(Int(dailyLimit)) min/day")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.lockInPrimary)
            }

            Text("If you want more time, request it from your pact.")
                .font(.system(size: 13))
                .foregroundColor(.lockInTextSecondary)

            Slider(value: $dailyLimit, in: 5...120, step: 5)
                .tint(.lockInPrimary)

            HStack {
                Text("5 min")
                Spacer()
                Text("2 hours")
            }
            .font(.system(size: 11))
            .foregroundColor(.lockInTextSecondary)
        }
        .lockInCard()
    }

    // MARK: - No Pact Warning
    private var noPactWarning: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.lockInWarning)
            Text("Join or create a pact first — you need an accountability partner to lock apps.")
                .font(.system(size: 13))
                .foregroundColor(.lockInTextSecondary)
        }
        .lockInCard()
    }
}
