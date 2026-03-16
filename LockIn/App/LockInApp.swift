import SwiftUI
import FamilyControls

@main
struct LockInApp: App {
    @StateObject private var authService = ScreenTimeAuthService()
    @StateObject private var shieldManager = ShieldManager()
    @AppStorage(AppConstants.hasCompletedOnboardingKey,
                store: UserDefaults(suiteName: AppConstants.appGroupIdentifier))
    private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(authService)
            .environmentObject(shieldManager)
        }
    }
}
