import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var shieldManager: ShieldManager
    @EnvironmentObject var pactService: PactService
    @EnvironmentObject var unlockRequestService: UnlockRequestService
    @EnvironmentObject var streakService: StreakService
    @State private var showUnlockRequestSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    focusRingSection
                    statsRow
                    actionButtons

                    if !unlockRequestService.pendingRequests.isEmpty {
                        pendingRequestsBanner
                    }

                    pactsSection

                    if pactService.myPacts.isEmpty {
                        noPactsCTA
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .refreshable {
                guard let userId = authService.currentUser?.id else { return }
                await pactService.fetchMyPacts(userId: userId)
                await unlockRequestService.fetchPendingRequests(userId: userId)
                await streakService.computeStreak(userId: userId)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .lockInScreenBackground()
            .sheet(isPresented: $showUnlockRequestSheet) {
                UnlockRequestSheet()
            }
        }
    }

    // MARK: - Header (greeting + streak badge)

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.system(size: 14))
                    .foregroundColor(.lockInTextSecondary)

                Text(authService.currentUser?.displayName ?? "there")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            Spacer()

            // Streak badge
            HStack(spacing: 5) {
                Text("🔥")
                    .font(.system(size: 18))
                Text("\(streakService.currentStreak)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.lockInPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.lockInPrimary.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.lockInPrimary.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(24)
            .accessibilityLabel("\(streakService.currentStreak) day streak")
        }
        .padding(.top, 8)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Late night grind"
        }
    }

    // MARK: - Focus Ring

    private var focusRingSection: some View {
        VStack(spacing: 16) {
            TimerRing(
                isActive: shieldManager.isLockActive,
                lockedAppCount: shieldManager.selectedApps.applicationTokens.count,
                streakDays: streakService.currentStreak,
                squadMembers: buildSquadMembers()
            )

            // Status text
            if shieldManager.isLockActive {
                VStack(spacing: 4) {
                    Text("Your squad can see you're focused")
                        .font(.system(size: 13))
                        .foregroundColor(.lockInTextSecondary)

                    if let duration = shieldManager.lockDurationFormatted {
                        Text("Locked for \(duration)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.lockInPrimary)
                    }
                }
            } else {
                Text("Lock apps to start your focus session")
                    .font(.system(size: 13))
                    .foregroundColor(.lockInTextTertiary)
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            StatPill(icon: "shield.fill", value: "\(shieldManager.selectedApps.applicationTokens.count)", label: "Blocked")
            StatDivider()
            StatPill(icon: "flame.fill", value: "\(streakService.currentStreak)d", label: "Streak")
            StatDivider()
            StatPill(icon: "hand.raised.fill", value: "\(unlockRequestService.myRequests.filter { $0.status == .denied }.count)", label: "Resisted")
        }
        .lockInCard()
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        Group {
            if shieldManager.isLockActive {
                LockInButton("Request Unlock", icon: "lock.open.fill", style: .ghost) {
                    showUnlockRequestSheet = true
                }
            } else if !pactService.myPacts.isEmpty {
                LockInButton("Lock In 🔥") {
                    NotificationCenter.default.post(name: .switchToLockTab, object: nil)
                }
            }
        }
    }

    // MARK: - Pending Requests Banner

    private var pendingRequestsBanner: some View {
        Button {
            NotificationCenter.default.post(name: .switchToRequestsTab, object: nil)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.lockInDanger.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(LockInGradient.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(unlockRequestService.pendingRequests.count) unlock request\(unlockRequestService.pendingRequests.count == 1 ? "" : "s")")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.lockInText)
                    Text("Your squad needs you")
                        .font(.system(size: 13))
                        .foregroundColor(.lockInTextSecondary)
                }
                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.lockInTextTertiary)
            }
            .lockInCard()
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.lockInPrimary.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("\(unlockRequestService.pendingRequests.count) pending unlock requests. Tap to review.")
    }

    // MARK: - Pacts

    private var pactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !pactService.myPacts.isEmpty {
                Text("YOUR PACTS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.lockInTextTertiary)
                    .tracking(1.5)
                    .padding(.leading, 4)

                ForEach(pactService.myPacts) { pact in
                    NavigationLink {
                        PactDetailView(pact: pact)
                    } label: {
                        PactCard(pact: pact, members: pactService.members(for: pact.id))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - No Pacts CTA

    private var noPactsCTA: some View {
        VStack(spacing: 20) {
            // Two connected emojis — the social hook
            HStack(spacing: 0) {
                Text("🔥")
                    .font(.system(size: 32))
                    .frame(width: 56, height: 56)
                    .background(Color.lockInPrimary.opacity(0.08))
                    .clipShape(Circle())

                // Connection line
                Rectangle()
                    .fill(LockInGradient.primary)
                    .frame(width: 30, height: 2)

                Text("💪")
                    .font(.system(size: 32))
                    .frame(width: 56, height: 56)
                    .background(Color.lockInSecondary.opacity(0.08))
                    .clipShape(Circle())
            }

            VStack(spacing: 6) {
                Text("Better together")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.lockInText)

                Text("Create a pact with a friend.\nThey approve your unlocks — and you approve theirs.")
                    .font(.system(size: 14))
                    .foregroundColor(.lockInTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            LockInButton("Create a Pact", icon: "plus") {
                NotificationCenter.default.post(name: .switchToPactsTab, object: nil)
            }
        }
        .lockInCard()
    }

    // MARK: - Helpers

    private func buildSquadMembers() -> [TimerRing.SquadMember] {
        guard let firstPact = pactService.myPacts.first else { return [] }
        let members = pactService.members(for: firstPact.id)
        let currentUserId = authService.currentUser?.id

        return members
            .filter { $0.userId != currentUserId } // Exclude self
            .prefix(4) // Max 4 orbiting
            .map { member in
                TimerRing.SquadMember(
                    id: member.id,
                    emoji: member.profile?.avatarEmoji ?? "🔥",
                    name: member.profile?.displayName ?? "?",
                    isLockedIn: false // TODO: fetch from lock_sessions
                )
            }
    }
}

// MARK: - Stat Pill

private struct StatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(LockInGradient.primary)

            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.lockInTextTertiary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct StatDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(width: 1, height: 36)
    }
}

// MARK: - Tab Switch Notifications

extension Notification.Name {
    static let switchToRequestsTab = Notification.Name("switchToRequestsTab")
    static let switchToPactsTab = Notification.Name("switchToPactsTab")
    static let switchToLockTab = Notification.Name("switchToLockTab")
    static let unlockApproved = Notification.Name("unlockApproved")
}
