import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @EnvironmentObject var authService: ScreenTimeAuthService
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color.lockInBackground.ignoresSafeArea()

            TabView(selection: $currentPage) {
                WelcomePageView(onNext: { currentPage = 1 })
                    .tag(0)

                ModeSelectionPageView(onNext: { currentPage = 2 })
                    .tag(1)

                PermissionPageView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Page dots
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i == currentPage ? Color.lockInPrimary : Color.lockInSurfaceLight)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Welcome Page
private struct WelcomePageView: View {
    let onNext: () -> Void

    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo
            ZStack {
                Circle()
                    .fill(Color.lockInPrimary.opacity(0.15))
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)

                Image(systemName: "lock.fill")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundColor(.lockInPrimary)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
            }

            VStack(spacing: 12) {
                Text("LockIn")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(.lockInText)

                Text("Lock your apps.\nLock in your focus.")
                    .font(.system(size: 18))
                    .foregroundColor(.lockInTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            LockInButton("Get Started", icon: "arrow.right") {
                onNext()
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 60)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
}

// MARK: - Mode Selection Page
private struct ModeSelectionPageView: View {
    let onNext: () -> Void
    @State private var selectedMode: AppConstants.UserMode?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("How will you use LockIn?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.lockInText)
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                ModeCard(
                    icon: "person.fill",
                    title: "Self Lock",
                    description: "Lock yourself out of distracting apps",
                    isSelected: selectedMode == .selfLock
                ) {
                    selectedMode = .selfLock
                }

                ModeCard(
                    icon: "person.2.fill",
                    title: "Guardian Mode",
                    description: "Set restrictions for someone else with a PIN",
                    isSelected: selectedMode == .guardian
                ) {
                    selectedMode = .guardian
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            if let mode = selectedMode {
                LockInButton("Continue", icon: "arrow.right") {
                    SharedDefaults.shared.setUserMode(mode)
                    onNext()
                }
                .padding(.horizontal, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer().frame(height: 60)
        }
        .animation(.spring(response: 0.4), value: selectedMode)
    }
}

// MARK: - Mode Card
private struct ModeCard: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .lockInPrimary : .lockInTextSecondary)
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.lockInText)

                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.lockInTextSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .lockInPrimary : .lockInSurfaceLight)
            }
            .padding(20)
            .background(isSelected ? Color.lockInPrimary.opacity(0.1) : Color.lockInSurface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.lockInPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Permission Page
private struct PermissionPageView: View {
    @EnvironmentObject var authService: ScreenTimeAuthService
    @State private var showSignIn = false
    @AppStorage(AppConstants.hasCompletedOnboardingKey,
                store: UserDefaults(suiteName: AppConstants.appGroupIdentifier))
    private var hasCompletedOnboarding = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "shield.checkered")
                .font(.system(size: 64))
                .foregroundColor(.lockInPrimary)

            VStack(spacing: 12) {
                Text("One More Thing")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.lockInText)

                Text("LockIn needs Screen Time access\nto block apps on your behalf.")
                    .font(.system(size: 16))
                    .foregroundColor(.lockInTextSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                LockInButton("Allow Screen Time", icon: "hourglass") {
                    Task {
                        await authService.requestAuthorization()
                    }
                }

                // Sign in with Apple
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { _ in
                    // Handled by AppleAuthService in production
                    hasCompletedOnboarding = true
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 52)
                .cornerRadius(16)
            }
            .padding(.horizontal, 24)

            if case .approved = authService.authorizationStatus {
                LockInButton("Let's Go", icon: "arrow.right") {
                    hasCompletedOnboarding = true
                }
                .padding(.horizontal, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer()
            Spacer().frame(height: 60)
        }
        .animation(.spring(response: 0.4), value: authService.authorizationStatus)
    }
}
