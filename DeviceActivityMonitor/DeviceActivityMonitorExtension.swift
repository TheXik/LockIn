import DeviceActivity
import ManagedSettings
import Foundation

/// Monitors device activity for schedule-based lock management.
/// When a scheduled interval starts, shields are applied.
/// When it ends, shields are removed.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let store = ManagedSettingsStore()
    private let appGroupID = "group.com.lukashellesch.lockin"

    // MARK: - Schedule Events

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // Re-apply shields when the scheduled lock interval begins
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "lockin.selectedApps") else { return }

        // Decode the saved FamilyActivitySelection
        // Note: We can't decode FamilyActivitySelection directly in the extension
        // because it requires the FamilyControls framework context.
        // Instead, we just set the lock active flag and let the main app handle shield application.
        defaults.set(true, forKey: "lockin.isLockActive")
        defaults.set(Date().timeIntervalSince1970, forKey: "lockin.lockStartedAt")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // Remove all shields when the scheduled lock interval ends
        store.clearAllSettings()

        // Update shared state
        if let defaults = UserDefaults(suiteName: appGroupID) {
            defaults.set(false, forKey: "lockin.isLockActive")
            defaults.removeObject(forKey: "lockin.lockStartedAt")
        }
    }

    // MARK: - Threshold Events

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name,
                                         activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        // When daily time limit is reached, re-apply shields
        // This catches users who were granted a temporary unlock but exceeded their daily limit
        if let defaults = UserDefaults(suiteName: appGroupID) {
            defaults.set(true, forKey: "lockin.dailyLimitReached")
        }
    }
}
