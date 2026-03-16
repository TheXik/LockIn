import ManagedSettings
import ManagedSettingsUI
import DeviceActivity
import Foundation

/// Handles user interaction with the shield overlay (unlock / dismiss).
class ShieldActionExtension: ShieldActionDelegate {

    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()

    override func handle(action: ShieldAction,
                         for application: ApplicationToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // User tapped "I Need This App" — grant temporary unlock
            temporaryUnlock(for: application)
            completionHandler(.close)

        case .secondaryButtonPressed:
            // User chose to stay locked
            completionHandler(.defer)

        @unknown default:
            completionHandler(.defer)
        }
    }

    override func handle(action: ShieldAction,
                         for webDomain: WebDomainToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)
        case .secondaryButtonPressed:
            completionHandler(.defer)
        @unknown default:
            completionHandler(.defer)
        }
    }

    // MARK: - Temporary Unlock

    /// Remove the shield for this specific app and schedule re-lock after 2 minutes.
    private func temporaryUnlock(for application: ApplicationToken) {
        // Check if guardian mode — if so, require PIN (handled in main app)
        let mode = SharedDefaults.shared.getUserMode()
        if mode == .guardian {
            // In guardian mode, don't allow shield bypass
            return
        }

        // Remove this app's shield
        store.shield.applications?.remove(application)

        // Create a profile to track this temporary unlock
        let profile = LockProfile(
            name: "temp-unlock",
            applicationTokens: Set([application]),
            categoryTokens: Set(),
            durationMinutes: 2
        )

        // Schedule re-shield after 2 minutes
        let now = Date.now
        let end = Calendar.current.date(byAdding: .minute, value: 2, to: now) ?? now

        let schedule = DeviceActivitySchedule(
            intervalStart: Calendar.current.dateComponents([.hour, .minute, .second], from: now),
            intervalEnd: Calendar.current.dateComponents([.hour, .minute, .second], from: end),
            repeats: false
        )

        let eventName = DeviceActivityEvent.Name(profile.id.uuidString)
        let event = DeviceActivityEvent(
            applications: Set([application]),
            threshold: DateComponents(minute: 2)
        )

        do {
            try center.startMonitoring(
                DeviceActivityName(profile.id.uuidString),
                during: schedule,
                events: [eventName: event]
            )
        } catch {
            // If monitoring fails, re-apply shield immediately
            store.shield.applications?.insert(application)
        }
    }
}
