import Foundation
import AuthenticationServices
import Supabase

/// Handles Sign in with Apple → Supabase Auth.
@MainActor
final class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: Profile?
    @Published var isLoading = true

    init() {
        Task { await listenForAuthChanges() }
    }

    // MARK: - Auth State

    private func listenForAuthChanges() async {
        for await (event, session) in supabase.auth.authStateChanges {
            guard [.initialSession, .signedIn, .signedOut].contains(event) else { continue }

            if let session {
                isAuthenticated = true
                await fetchOrCreateProfile(userId: session.user.id)
            } else {
                isAuthenticated = false
                currentUser = nil
            }
            isLoading = false
        }
    }

    // MARK: - Sign In with Apple

    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        do {
            guard let credential = try result.get().credential as? ASAuthorizationAppleIDCredential,
                  let idTokenData = credential.identityToken,
                  let idToken = String(data: idTokenData, encoding: .utf8)
            else { return }

            try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken)
            )

            // Apple only sends name on FIRST sign-in — capture it now
            if let fullName = credential.fullName {
                let name = [fullName.givenName, fullName.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                if !name.isEmpty {
                    try? await supabase.auth.update(
                        user: UserAttributes(data: ["full_name": .string(name)])
                    )
                }
            }
        } catch {
            print("Apple sign-in failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Profile

    private func fetchOrCreateProfile(userId: UUID) async {
        do {
            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            currentUser = profile
        } catch {
            // Profile doesn't exist yet — create one
            let emojis = ["🔥", "💪", "🎯", "⚡", "🧠", "🚀", "🦾", "🏆"]
            let newProfile = [
                "id": userId.uuidString,
                "display_name": "User",
                "avatar_emoji": emojis.randomElement() ?? "🔥"
            ]
            do {
                let created: Profile = try await supabase
                    .from("profiles")
                    .insert(newProfile)
                    .select()
                    .single()
                    .execute()
                    .value
                currentUser = created
            } catch {
                print("Failed to create profile: \(error)")
            }
        }
    }

    func updateDisplayName(_ name: String) async {
        guard var user = currentUser else { return }
        user.displayName = name
        do {
            try await supabase
                .from("profiles")
                .update(["display_name": name])
                .eq("id", value: user.id.uuidString)
                .execute()
            currentUser = user
        } catch {
            print("Failed to update name: \(error)")
        }
    }

    func signOut() async {
        try? await supabase.auth.signOut()
        isAuthenticated = false
        currentUser = nil
    }
}
