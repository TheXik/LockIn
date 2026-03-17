import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var shieldManager: ShieldManager
    @EnvironmentObject var pactService: PactService
    @EnvironmentObject var unlockRequestService: UnlockRequestService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    greetingSection
                    statusSection

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
            .navigationTitle("LockIn")
            .lockInScreenBackground()
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Greeting
    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hey, \(authService.currentUser?.displayName ?? "there") 👋")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.lockInText)

                Text(shieldManager.isLockActive ? "You're locked in. Stay hard." : "Ready to lock in?")
                    .font(.system(size: 15))
                    .foregroundColor(.lockInTextSecondary)
            }
            Spacer()
            Text(authService.currentUser?.avatarEmoji ?? "🔥")
                .font(.system(size: 36))
        }
    }

    // MARK: - Status
    private var statusSection: some View {
        VStack(spacing: 16) {
            TimerRing(
                progress: shieldManager.isLockActive ? 0.7 : 0,
                timeRemaining: shieldManager.isLockActive ? "active" : "00:00",
                isActive: shieldManager.isLockActive
            )

            if shieldManager.isLockActive {
                LockInButton("Request Unlock", icon: "lock.open.fill", style: .ghost) {
                    // navigate to unlock request flow
                }

                Text("\(shieldManager.selectedApps.applicationTokens.count) apps locked")
                    .font(.system(size: 13))
                    .foregroundColor(.lockInTextSecondary)
            }
        }
        .lockInCard()
    }

    // MARK: - Pending Requests
    private var pendingRequestsBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.badge.fill")
                .foregroundColor(.lockInPrimary)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(unlockRequestService.pendingRequests.count) unlock requests")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.lockInText)
                Text("Your pact members need you")
                    .font(.system(size: 13))
                    .foregroundColor(.lockInTextSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.lockInTextSecondary)
        }
        .lockInCard()
    }

    // MARK: - Pacts
    private var pactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !pactService.myPacts.isEmpty {
                Text("YOUR PACTS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.lockInTextSecondary)
                    .tracking(1.5)

                ForEach(pactService.myPacts) { pact in
                    PactCard(pact: pact, members: pactService.currentPactMembers) {}
                }
            }
        }
    }

    // MARK: - No Pacts CTA
    private var noPactsCTA: some View {
        VStack(spacing: 16) {
            Text("👥")
                .font(.system(size: 48))

            Text("Find your accountability partner")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.lockInText)
                .multilineTextAlignment(.center)

            Text("Create a pact with your co-founder or friend.\nHold each other accountable.")
                .font(.system(size: 14))
                .foregroundColor(.lockInTextSecondary)
                .multilineTextAlignment(.center)

            LockInButton("Create a Pact", icon: "plus") {}
        }
        .lockInCard()
    }
}
