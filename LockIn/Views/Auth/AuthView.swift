import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showAnimation = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 20) {
                    Text("🔒")
                        .font(.system(size: 72))
                        .scaleEffect(showAnimation ? 1 : 0.5)
                        .opacity(showAnimation ? 1 : 0)

                    VStack(spacing: 8) {
                        Text("LockIn")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundColor(.white)

                        Text("Accountability, together.")
                            .font(.system(size: 17))
                            .foregroundColor(.lockInTextSecondary)
                    }
                    .opacity(showAnimation ? 1 : 0)
                }

                Spacer()

                // Features
                VStack(spacing: 16) {
                    FeatureRow(emoji: "👥", text: "Lock apps with your co-founder")
                    FeatureRow(emoji: "🔐", text: "Only they can approve unlocks")
                    FeatureRow(emoji: "📅", text: "Set schedules and daily limits")
                }
                .padding(.horizontal, 32)
                .opacity(showAnimation ? 1 : 0)

                Spacer()

                // Sign in
                VStack(spacing: 16) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task { await authService.handleAppleSignIn(result) }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 54)
                    .cornerRadius(14)

                    Text("Your data stays private. Always.")
                        .font(.system(size: 12))
                        .foregroundColor(.lockInTextSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                showAnimation = true
            }
        }
    }
}

private struct FeatureRow: View {
    let emoji: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.system(size: 24))
                .frame(width: 40)

            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)

            Spacer()
        }
    }
}
