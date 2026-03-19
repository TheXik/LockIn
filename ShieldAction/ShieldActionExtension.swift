import ManagedSettings
import ManagedSettingsUI
import Foundation

/// Handles user interaction with the shield overlay.
/// Primary button opens LockIn app for unlock request flow.
/// Secondary button keeps the shield up (stay focused).
class ShieldActionExtension: ShieldActionDelegate {

    override func handle(action: ShieldAction,
                         for application: ApplicationToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleAction(action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction,
                         for webDomain: WebDomainToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleAction(action, completionHandler: completionHandler)
    }

    private func handleAction(_ action: ShieldAction,
                              completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // "Open LockIn" — close shield so user can switch to LockIn app.
            // Write a flag so the app knows to open the Requests tab on next launch.
            if let defaults = UserDefaults(suiteName: "group.com.lockin.app") {
                defaults.set(true, forKey: "lockin.pendingUnlockFromShield")
                defaults.set(Date().timeIntervalSince1970, forKey: "lockin.shieldTapTimestamp")
            }
            // .close dismisses the shield overlay so the user can navigate to LockIn
            completionHandler(.close)

        case .secondaryButtonPressed:
            // "Stay focused" — keep the shield up, don't let them through
            completionHandler(.none)

        @unknown default:
            completionHandler(.none)
        }
    }
}
