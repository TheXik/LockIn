import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var shieldManager: ShieldManager
    @EnvironmentObject var screenTimeAuth: ScreenTimeAuthService
    @EnvironmentObject var pushService: PushNotificationService
    @EnvironmentObject var streakService: StreakService
    @State private var showResetConfirmation = false
    @State private var showSignOutConfirmation = false
    @State private var showPrivacyPolicy = false
    @State private var showTerms = false
    @State private var editingName = false
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    profileSection
                    streakStatsSection
                    notificationSection
                    screenTimeSection
                    dangerSection
                    legalSection
                    accountSection

                    Text("LockIn v1.0")
                        .font(.system(size: 12))
                        .foregroundColor(.lockInTextTertiary)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .navigationTitle("Settings")
            .lockInScreenBackground()
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Edit Name", isPresented: $editingName) {
                TextField("Your name", text: $newName)
                    .onChange(of: newName) { _ in
                        if newName.count > 100 { newName = String(newName.prefix(100)) }
                    }
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    Task { await authService.updateDisplayName(trimmed) }
                }
            }
            .alert("Remove All Locks?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Remove All", role: .destructive) {
                    shieldManager.deactivateShield(userId: authService.currentUser?.id)
                }
            } message: {
                Text("This will unlock all blocked apps immediately. Your pact members will be notified.")
            }
            .alert("Sign Out?", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task { await authService.signOut() }
                }
            } message: {
                Text("You'll need to sign in again to use LockIn.")
            }
        }
    }

    // MARK: - Profile
    private var profileSection: some View {
        HStack(spacing: 14) {
            let emoji = authService.currentUser?.avatarEmoji ?? "🔥"

            Text(emoji)
                .font(.system(size: 24))
                .frame(width: 48, height: 48)
                .background(Color.lockInPrimary.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(authService.currentUser?.displayName ?? "User")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.lockInText)

                Text("Signed in with Apple")
                    .font(.system(size: 13))
                    .foregroundColor(.lockInTextSecondary)
            }

            Spacer()

            Button {
                newName = authService.currentUser?.displayName ?? ""
                editingName = true
            } label: {
                Text("Edit")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.lockInPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.lockInPrimary.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .lockInCard()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Streak Stats
    private var streakStatsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("YOUR STATS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.lockInTextTertiary)
                .tracking(1.5)

            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("\(streakService.currentStreak)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.lockInPrimary)
                    Text("Current\nStreak")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.lockInTextTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 1, height: 36)

                VStack(spacing: 4) {
                    Text("\(streakService.longestStreak)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.lockInSecondary)
                    Text("Longest\nStreak")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.lockInTextTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 1, height: 36)

                VStack(spacing: 4) {
                    Text("\(streakService.totalLockDays)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.lockInSuccess)
                    Text("Total\nDays")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.lockInTextTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .lockInCard()
    }

    // MARK: - Notifications
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("NOTIFICATIONS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.lockInTextTertiary)
                .tracking(1.5)

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill((pushService.isPermissionGranted ? Color.lockInSuccess : Color.lockInWarning).opacity(0.12))
                        .frame(width: 36, height: 36)

                    Image(systemName: pushService.isPermissionGranted ? "bell.badge.fill" : "bell.slash")
                        .font(.system(size: 15))
                        .foregroundColor(pushService.isPermissionGranted ? .lockInSuccess : .lockInWarning)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(pushService.isPermissionGranted ? "Push Notifications Active" : "Notifications Disabled")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.lockInText)
                    Text(pushService.isPermissionGranted ? "You'll be notified when squad members need you" : "Enable to get unlock request alerts")
                        .font(.system(size: 13))
                        .foregroundColor(.lockInTextSecondary)
                }
                Spacer()
            }

            if !pushService.isPermissionGranted {
                LockInButton("Enable Notifications", icon: "bell.badge", style: .secondary) {
                    Task { _ = await pushService.requestPermission() }
                }
            }
        }
        .lockInCard()
    }

    // MARK: - Screen Time
    private var screenTimeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SCREEN TIME")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.lockInTextTertiary)
                .tracking(1.5)

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.12))
                        .frame(width: 36, height: 36)

                    Image(systemName: statusIcon)
                        .font(.system(size: 15))
                        .foregroundColor(statusColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.lockInText)
                    Text(statusSubtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.lockInTextSecondary)
                }
                Spacer()
            }

            if case .notDetermined = screenTimeAuth.authorizationStatus {
                LockInButton("Allow Access", icon: "checkmark.shield", style: .secondary) {
                    Task { await screenTimeAuth.requestAuthorization() }
                }
            }
        }
        .lockInCard()
    }

    private var statusIcon: String {
        switch screenTimeAuth.authorizationStatus {
        case .approved: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .notDetermined: return "questionmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        switch screenTimeAuth.authorizationStatus {
        case .approved: return .lockInSuccess
        case .denied, .error: return .lockInDanger
        case .notDetermined: return .lockInWarning
        }
    }

    private var statusTitle: String {
        switch screenTimeAuth.authorizationStatus {
        case .approved: return "Screen Time Active"
        case .denied: return "Access Denied"
        case .notDetermined: return "Not Set Up"
        case .error(let msg): return "Error: \(msg)"
        }
    }

    private var statusSubtitle: String {
        switch screenTimeAuth.authorizationStatus {
        case .approved: return "LockIn can manage your apps"
        case .denied: return "Go to Settings > Screen Time to enable"
        case .notDetermined: return "Tap below to enable app blocking"
        case .error: return "Try again or restart the app"
        }
    }

    // MARK: - Danger Zone
    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("DANGER ZONE")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.lockInTextTertiary)
                .tracking(1.5)

            Button { showResetConfirmation = true } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.lockInDanger.opacity(0.12))
                            .frame(width: 36, height: 36)

                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.lockInDanger)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Remove All Locks")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.lockInDanger)
                        Text("Pact members will be notified")
                            .font(.system(size: 13))
                            .foregroundColor(.lockInTextSecondary)
                    }
                    Spacer()
                }
            }
        }
        .lockInCard()
    }

    // MARK: - Legal
    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("LEGAL")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.lockInTextTertiary)
                .tracking(1.5)

            Button { showPrivacyPolicy = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.lockInTextSecondary)
                        .frame(width: 24)
                    Text("Privacy Policy")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.lockInText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.lockInTextTertiary)
                }
            }

            Button { showTerms = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.lockInTextSecondary)
                        .frame(width: 24)
                    Text("Terms of Service")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.lockInText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.lockInTextTertiary)
                }
            }
        }
        .lockInCard()
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showTerms) {
            TermsOfServiceView()
        }
    }

    // MARK: - Account
    private var accountSection: some View {
        Button { showSignOutConfirmation = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15))
                    .foregroundColor(.lockInTextSecondary)
                    .frame(width: 24)

                Text("Sign Out")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.lockInTextSecondary)

                Spacer()
            }
        }
        .lockInCard()
    }
}
