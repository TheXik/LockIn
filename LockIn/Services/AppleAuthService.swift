import Foundation
import AuthenticationServices

/// Sign in with Apple service — lightweight, no backend needed for MVP.
@MainActor
final class AppleAuthService: ObservableObject {
    @Published var isSignedIn = false
    @Published var userName: String?
    @Published var userEmail: String?

    private let userIdKey = "appleUserId"
    private let userNameKey = "appleUserName"

    init() {
        checkExistingCredential()
    }

    /// Check if we already have a valid Apple ID credential.
    func checkExistingCredential() {
        guard let userId = UserDefaults.standard.string(forKey: userIdKey) else { return }

        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userId) { [weak self] state, _ in
            DispatchQueue.main.async {
                switch state {
                case .authorized:
                    self?.isSignedIn = true
                    self?.userName = UserDefaults.standard.string(forKey: self?.userNameKey ?? "")
                case .revoked, .notFound:
                    self?.signOut()
                default:
                    break
                }
            }
        }
    }

    /// Handle successful Sign in with Apple.
    func handleAuthorization(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }

            let userId = credential.user
            UserDefaults.standard.set(userId, forKey: userIdKey)

            if let fullName = credential.fullName {
                let name = [fullName.givenName, fullName.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                if !name.isEmpty {
                    userName = name
                    UserDefaults.standard.set(name, forKey: userNameKey)
                }
            }

            if let email = credential.email {
                userEmail = email
            }

            isSignedIn = true

        case .failure(let error):
            print("Sign in with Apple failed: \(error.localizedDescription)")
        }
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: userNameKey)
        isSignedIn = false
        userName = nil
        userEmail = nil
    }
}
