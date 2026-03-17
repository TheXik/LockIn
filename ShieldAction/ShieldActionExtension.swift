import ManagedSettings
import ManagedSettingsUI
import Foundation

/// Handles user interaction with the shield overlay.
/// In LockIn, ALL unlocks go through the pact approval flow — no self-unlock.
class ShieldActionExtension: ShieldActionDelegate {

    override func handle(action: ShieldAction,
                         for application: ApplicationToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // "Request Unlock" — dismiss shield, user must open LockIn app to request
            // The app remains blocked; this just closes the overlay
            completionHandler(.defer)

        case .secondaryButtonPressed:
            // "Stay Locked In" — keep shield up
            completionHandler(.defer)

        @unknown default:
            completionHandler(.defer)
        }
    }

    override func handle(action: ShieldAction,
                         for webDomain: WebDomainToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        // Same behavior for web domains
        completionHandler(.defer)
    }
}
