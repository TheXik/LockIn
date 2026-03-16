import Foundation
import FamilyControls

/// Handles FamilyControls authorization — the gateway to Screen Time APIs.
@MainActor
final class ScreenTimeAuthService: ObservableObject {
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined

    enum AuthorizationStatus {
        case notDetermined
        case approved
        case denied
        case error(String)
    }

    /// Request individual authorization (user locks themselves).
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorizationStatus = .approved
        } catch {
            authorizationStatus = .error(error.localizedDescription)
        }
    }

    /// Check current authorization state on launch.
    func checkAuthorization() {
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved:
            authorizationStatus = .approved
        case .denied:
            authorizationStatus = .denied
        case .notDetermined:
            authorizationStatus = .notDetermined
        @unknown default:
            authorizationStatus = .notDetermined
        }
    }
}
