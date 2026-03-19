import SwiftUI

/// Main tab navigation after authentication.
struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var pactService: PactService
    @EnvironmentObject var unlockRequestService: UnlockRequestService
    @EnvironmentObject var screenTimeAuth: ScreenTimeAuthService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            PactListView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Pacts")
                }
                .tag(1)

            LockSetupView()
                .tabItem {
                    Image(systemName: "lock.fill")
                    Text("Lock")
                }
                .tag(2)

            RequestsView()
                .tabItem {
                    Image(systemName: "bell.fill")
                    Text("Requests")
                }
                .badge(unlockRequestService.pendingRequests.count)
                .tag(3)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(4)
        }
        .tint(.lockInPrimary)
        .task {
            guard let userId = authService.currentUser?.id else { return }
            await pactService.fetchMyPacts(userId: userId)
            await unlockRequestService.fetchPendingRequests(userId: userId)
            await unlockRequestService.listenForNewRequests(userId: userId)

            // Check if user came from shield "Open LockIn" button
            checkShieldDeepLink()
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToRequestsTab)) { _ in
            selectedTab = 3
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToPactsTab)) { _ in
            selectedTab = 1
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToLockTab)) { _ in
            selectedTab = 2
        }
    }

    /// Check App Group for shield deep-link flag (set by ShieldActionExtension).
    private func checkShieldDeepLink() {
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) else { return }
        let pending = defaults.bool(forKey: "lockin.pendingUnlockFromShield")
        guard pending else { return }

        // Clear the flag
        defaults.set(false, forKey: "lockin.pendingUnlockFromShield")
        defaults.removeObject(forKey: "lockin.shieldTapTimestamp")

        // Navigate to Requests tab
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            selectedTab = 3
        }
    }
}
