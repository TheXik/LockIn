#if DEBUG
import SwiftUI
import FamilyControls

// TEMPORARY screenshot harness. Renders any post-login screen with seeded mock
// data so the redesign can be captured without Sign in with Apple. Selected via
// the LK_DEBUG_SCREEN launch env var. NOT shipped — delete before release.

enum DebugScreen: String {
    case home, requests, pacts, pactDetail, lock, settings, onboarding, locked
}

struct DebugRootView: View {
    let screen: DebugScreen

    @StateObject private var auth = AuthService()
    @StateObject private var pact = PactService()
    @StateObject private var unlock = UnlockRequestService()
    @StateObject private var screenTime = ScreenTimeAuthService()
    @StateObject private var shield = ShieldManager()
    @StateObject private var streak = StreakService()
    private let push = PushNotificationService.shared

    @State private var completed = false

    var body: some View {
        content
            .environmentObject(auth)
            .environmentObject(pact)
            .environmentObject(unlock)
            .environmentObject(screenTime)
            .environmentObject(shield)
            .environmentObject(streak)
            .environmentObject(push)
            .onAppear {
                seed()
                // Re-seed after the screens' own fetch-on-appear would have run,
                // so a failed network fetch can't blank the mock data.
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { seed() }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch screen {
        case .home: HomeView()
        case .requests: RequestsView()
        case .pacts: PactListView()
        case .pactDetail:
            NavigationStack {
                if let p = pact.myPacts.first { PactDetailView(pact: p) }
            }
        case .lock: LockSetupView()
        case .settings: SettingsView()
        case .onboarding: OnboardingView(hasCompletedOnboarding: $completed)
        case .locked: LockedMotivationView()
        }
    }

    private func seed() {
        let meId = UUID(), petrId = UUID(), jakubId = UUID()
        let me = Profile(id: meId, displayName: "You", avatarEmoji: "🦊", pushToken: nil, createdAt: Date())
        let petr = Profile(id: petrId, displayName: "Petr", avatarEmoji: "🐻", pushToken: nil, createdAt: Date())
        let jakub = Profile(id: jakubId, displayName: "Jakub", avatarEmoji: "🦅", pushToken: nil, createdAt: Date())

        auth.currentUser = me
        auth.isAuthenticated = true
        auth.isLoading = false

        let pactId = UUID()
        pact.myPacts = [Pact(id: pactId, name: "The Grind", inviteCode: "K7X9Q2", createdBy: meId, createdAt: Date())]
        pact.pactMembers = [pactId: [
            PactMember(id: UUID(), pactId: pactId, userId: meId, joinedAt: Date(), profile: me),
            PactMember(id: UUID(), pactId: pactId, userId: petrId, joinedAt: Date(), profile: petr),
            PactMember(id: UUID(), pactId: pactId, userId: jakubId, joinedAt: Date(), profile: jakub),
        ]]

        streak.currentStreak = 12
        streak.longestStreak = 21
        streak.totalLockDays = 34
        streak.totalLocksThisWeek = 5

        shield.isLockActive = true
        shield.lockStartedAt = Date().addingTimeInterval(-3720)

        unlock.pendingRequests = [
            UnlockRequest(id: UUID(), requesterId: petrId, pactId: pactId, lockSessionId: nil,
                          appIdentifier: "Instagram", reason: "Need to check a message real quick",
                          status: .pending, responderId: nil, respondedAt: nil,
                          createdAt: Date().addingTimeInterval(-240)),
        ]
        unlock.myRequests = [
            UnlockRequest(id: UUID(), requesterId: meId, pactId: pactId, lockSessionId: nil,
                          appIdentifier: "TikTok", reason: "five minutes, I swear",
                          status: .denied, responderId: petrId, respondedAt: Date(),
                          createdAt: Date().addingTimeInterval(-1500)),
        ]
    }
}
#endif
