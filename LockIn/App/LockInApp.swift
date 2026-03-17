import SwiftUI
import FamilyControls

@main
struct LockInApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var screenTimeAuth = ScreenTimeAuthService()
    @StateObject private var shieldManager = ShieldManager()
    @StateObject private var pactService = PactService()
    @StateObject private var unlockRequestService = UnlockRequestService()

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoading {
                    SplashView()
                } else if !authService.isAuthenticated {
                    AuthView()
                } else {
                    MainTabView()
                }
            }
            .preferredColorScheme(.dark)
            .environmentObject(authService)
            .environmentObject(screenTimeAuth)
            .environmentObject(shieldManager)
            .environmentObject(pactService)
            .environmentObject(unlockRequestService)
        }
    }
}

// MARK: - Splash
struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("🔒")
                    .font(.system(size: 56))
                Text("LockIn")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }
}
