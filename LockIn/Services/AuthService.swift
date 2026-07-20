import Foundation
import AuthenticationServices
import Supabase

/// Handles Sign in with Apple → Supabase Auth.
@MainActor
final class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: Profile?
    @Published var isLoading = true

    /// Closure called on sign-out so the app can clean up other services.
    var onSignOut: (() async -> Void)?

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
            #if DEBUG
            print("Apple sign-in failed: \(error.localizedDescription)")
            #endif
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
                #if DEBUG
                print("Failed to create profile: \(error)")
                #endif
            }
        }
    }

    func updateDisplayName(_ name: String) async {
        guard var user = currentUser else { return }

        // Input validation
        let sanitized = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(100))
        guard !sanitized.isEmpty else { return }

        user.displayName = sanitized
        do {
            try await supabase
                .from("profiles")
                .update(["display_name": sanitized])
                .eq("id", value: user.id.uuidString)
                .execute()
            currentUser = user
        } catch {
            #if DEBUG
            print("Failed to update name: \(error)")
            #endif
        }
    }

    func signOut() async {
        // Clean up other services first
        await onSignOut?()

        do {
            try await supabase.auth.signOut()
        } catch {
            #if DEBUG
            print("Sign-out error: \(error)")
            #endif
        }

        isAuthenticated = false
        currentUser = nil
    }

    /// Permanently deletes the account and ALL associated data — profile, pact
    /// memberships, lock sessions, unlock requests, push token, and the auth user.
    /// Required by App Store guideline 5.1.1(v). Irreversible. Throws so the UI
    /// can surface a failure and keep the user signed in.
    func deleteAccount() async throws {
        // Server-side cascade (see supabase/migrations/004_account_deletion.sql).
        try await supabase.rpc("delete_my_account").execute()

        // The auth user is gone now — tear down services and drop the local session.
        await onSignOut?()
        try? await supabase.auth.signOut()
        isAuthenticated = false
        currentUser = nil
    }
}
