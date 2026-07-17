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
                VStack(alignment: .leading, spacing: LKSpace.xl) {
                    headerSection
                    heroStatement
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
                .padding(.horizontal, LKSpace.xl)
                .padding(.top, LKSpace.sm)
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
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText.uppercased())
                    .font(.lkMicro)
                    .tracking(1.6)
                    .foregroundColor(.lockInTextTertiary)

                Text(authService.currentUser?.displayName ?? "there")
                    .font(.system(size: 26, weight: .heavy))
                    .tracking(-0.5)
                    .foregroundColor(.lockInText)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            Spacer(minLength: LKSpace.md)

            // Streak — a small mono figure, not an emoji badge
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LockInGradient.ember)
                Text("\(streakService.currentStreak)")
                    .font(.lkMono(18, .heavy))
                    .foregroundColor(.lockInPrimary)
            }
            .padding(.horizontal, LKSpace.md)
            .padding(.vertical, 7)
            .background(Color.lockInPrimary.opacity(0.08))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.lockInPrimary.opacity(0.18), lineWidth: 1))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(streakService.currentStreak) day streak")
        }
        .padding(.top, LKSpace.sm)
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

    // MARK: - Hero statement (the editorial headline)

    private var heroStatement: some View {
        Group {
            if shieldManager.isLockActive {
                Text("You're\n").foregroundColor(.lockInText)
                    + Text("locked in.").foregroundColor(.lockInPrimary)
            } else if !pactService.myPacts.isEmpty {
                Text("Ready when\n").foregroundColor(.lockInText)
                    + Text("you are.").foregroundColor(.lockInPrimary)
            } else {
                Text("Focus is a\n").foregroundColor(.lockInText)
                    + Text("team sport.").foregroundColor(.lockInPrimary)
            }
        }
        .font(.system(size: 40, weight: .black))
        .tracking(-1.2)
        .lineSpacing(-2)
        .fixedSize(horizontal: false, vertical: true)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Focus Ring

    private var focusRingSection: some View {
        VStack(alignment: .leading, spacing: LKSpace.lg) {
            TimerRing(
                isActive: shieldManager.isLockActive,
                lockedAppCount: shieldManager.selectedApps.applicationTokens.count,
                streakDays: streakService.currentStreak,
                squadMembers: buildSquadMembers()
            )
            .frame(maxWidth: .infinity)

            // Status line — left aligned, editorial
            if shieldManager.isLockActive {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Your squad can see you're focused.")
                        .font(.lkCallout)
                        .foregroundColor(.lockInTextSecondary)

                    if let duration = shieldManager.lockDurationFormatted {
                        (Text("Locked for ").foregroundColor(.lockInTextSecondary)
                            + Text(duration).foregroundColor(.lockInPrimary))
                            .font(.lkMono(14, .semibold))
                    }
                }
            } else {
                Text("Lock the apps that own you to start a session.")
                    .font(.lkCallout)
                    .foregroundColor(.lockInTextTertiary)
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(alignment: .top, spacing: LKSpace.xxl) {
            StatBlock(
                value: "\(shieldManager.selectedApps.applicationTokens.count)",
                label: "Blocked"
            )
            StatBlock(
                value: "\(streakService.currentStreak)",
                label: "Day streak"
            )
            StatBlock(
                value: "\(unlockRequestService.myRequests.filter { $0.status == .denied }.count)",
                label: "Resisted"
            )
            Spacer(minLength: 0)
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
                LockInButton("Lock In", icon: "flame.fill") {
                    NotificationCenter.default.post(name: .switchToLockTab, object: nil)
                }
            }
        }
    }

    // MARK: - Pending Requests Banner

    private var pendingRequestsBanner: some View {
        let count = unlockRequestService.pendingRequests.count
        return Button {
            NotificationCenter.default.post(name: .switchToRequestsTab, object: nil)
        } label: {
            HStack(spacing: LKSpace.lg) {
                // The count is the accent — a big mono figure, not an icon-in-a-box
                Text("\(count)")
                    .font(.lkMono(30, .heavy))
                    .foregroundStyle(LockInGradient.ember)
                    .contentTransition(.numericText())

                VStack(alignment: .leading, spacing: 2) {
                    Text(count == 1 ? "unlock request" : "unlock requests")
                        .font(.lkBodyStrong)
                        .foregroundColor(.lockInText)
                    Text("Your squad is waiting on you.")
                        .font(.lkCaption)
                        .foregroundColor(.lockInTextSecondary)
                }
                Spacer(minLength: LKSpace.sm)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.lockInTextTertiary)
            }
            .lockInCard()
            .overlay(
                RoundedRectangle(cornerRadius: LKRadius.lg, style: .continuous)
                    .stroke(Color.lockInPrimary.opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("\(count) pending unlock request\(count == 1 ? "" : "s"). Tap to review.")
    }

    // MARK: - Pacts

    private var pactsSection: some View {
        VStack(alignment: .leading, spacing: LKSpace.md) {
            if !pactService.myPacts.isEmpty {
                Text("YOUR PACTS")
                    .font(.lkMicro)
                    .foregroundColor(.lockInTextTertiary)
                    .tracking(2)
                    .padding(.leading, LKSpace.xs)

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
        VStack(alignment: .leading, spacing: LKSpace.lg) {
            Text("Nobody holds\nyour key yet.")
                .font(.system(size: 24, weight: .black))
                .tracking(-0.6)
                .lineSpacing(-1)
                .foregroundColor(.lockInText)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.7)

            Text("Start a pact with a friend. They approve your unlocks — and you approve theirs. That accountability is the whole trick.")
                .font(.lkBody)
                .foregroundColor(.lockInTextSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            LockInButton("Create a Pact", icon: "plus") {
                NotificationCenter.default.post(name: .switchToPactsTab, object: nil)
            }
            .padding(.top, LKSpace.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

// MARK: - Stat Block

private struct StatBlock: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.lkMono(26, .heavy))
                .foregroundColor(.lockInText)

            Text(label.uppercased())
                .font(.lkMicro)
                .foregroundColor(.lockInTextTertiary)
                .tracking(0.8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}

// MARK: - Tab Switch Notifications

extension Notification.Name {
    static let switchToRequestsTab = Notification.Name("switchToRequestsTab")
    static let switchToPactsTab = Notification.Name("switchToPactsTab")
    static let switchToLockTab = Notification.Name("switchToLockTab")
    static let unlockApproved = Notification.Name("unlockApproved")
}
