import SwiftUI

struct HomeView: View {
    @EnvironmentObject var shieldManager: ShieldManager
    @State private var showQuickLock = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Status card
                    statusCard

                    // Quick lock buttons
                    quickLockSection

                    // Active sessions
                    if shieldManager.isLockActive {
                        activeSessionCard
                    }

                    // Saved profiles
                    savedProfilesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .navigationTitle("LockIn")
            .lockInGradientBackground()
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Status Card
    private var statusCard: some View {
        VStack(spacing: 16) {
            TimerRing(
                progress: shieldManager.isLockActive ? 0.65 : 0,
                timeRemaining: shieldManager.isLockActive ? "23:45" : "00:00",
                isActive: shieldManager.isLockActive
            )

            Text(shieldManager.isLockActive ? "You're locked in. Stay focused." : "Ready to lock in?")
                .font(.system(size: 16))
                .foregroundColor(.lockInTextSecondary)
        }
        .lockInCard()
    }

    // MARK: - Quick Lock
    private var quickLockSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK LOCK")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.lockInTextSecondary)
                .tracking(1.5)

            HStack(spacing: 12) {
                QuickLockButton(minutes: 15, icon: "15.circle.fill") {
                    shieldManager.quickLock(minutes: 15)
                }
                QuickLockButton(minutes: 30, icon: "30.circle.fill") {
                    shieldManager.quickLock(minutes: 30)
                }
                QuickLockButton(minutes: 60, icon: "60.circle.fill") {
                    shieldManager.quickLock(minutes: 60)
                }
                QuickLockButton(minutes: 120, icon: "clock.fill") {
                    shieldManager.quickLock(minutes: 120)
                }
            }
        }
    }

    // MARK: - Active Session
    private var activeSessionCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.lockInSuccess)
                Text("Active Session")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.lockInText)
                Spacer()
            }

            HStack {
                AppIconGrid(
                    appTokens: shieldManager.selectedApps.applicationTokens,
                    maxDisplay: 8
                )
            }

            LockInButton("End Session", icon: "lock.open.fill", style: .danger) {
                shieldManager.deactivateShield()
            }
        }
        .lockInCard()
    }

    // MARK: - Saved Profiles
    private var savedProfilesSection: some View {
        let profiles = SharedDefaults.shared.getLockProfiles()

        return VStack(alignment: .leading, spacing: 12) {
            if !profiles.isEmpty {
                Text("SAVED PROFILES")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lockInTextSecondary)
                    .tracking(1.5)

                ForEach(profiles) { profile in
                    ProfileRow(profile: profile) {
                        shieldManager.activateProfile(profile)
                    }
                }
            }
        }
    }
}

// MARK: - Quick Lock Button
private struct QuickLockButton: View {
    let minutes: Int
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.lockInPrimary)

                Text("\(minutes)m")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lockInText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.lockInSurface)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Profile Row
private struct ProfileRow: View {
    let profile: LockProfile
    let onActivate: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.lockInText)

                Text("\(profile.applicationTokens.count) apps · \(profile.durationMinutes) min")
                    .font(.system(size: 13))
                    .foregroundColor(.lockInTextSecondary)
            }

            Spacer()

            Button(action: onActivate) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.lockInPrimary)
                    .padding(12)
                    .background(Color.lockInPrimary.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .lockInCard()
    }
}
