import DeviceActivity
import ManagedSettings
import Foundation

/// Monitors device activity events and re-applies shields when unlock timers expire.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let store = ManagedSettingsStore()

    // Called when a monitored time interval ends (e.g., temporary unlock expires).
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // Look up the profile associated with this activity
        guard let profileId = UUID(uuidString: activity.rawValue) else { return }

        let profiles = SharedDefaults.shared.getLockProfiles()
        guard let profile = profiles.first(where: { $0.id == profileId }) else {
            // No profile found — this might be a temporary unlock. Re-apply all shields.
            reapplyAllShields()
            return
        }

        // Re-apply shield for these specific apps
        if !profile.applicationTokens.isEmpty {
            var currentApps = store.shield.applications ?? Set()
            currentApps.formUnion(profile.applicationTokens)
            store.shield.applications = currentApps
        }

        if !profile.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(profile.categoryTokens)
        }

        // Mark profile as inactive
        var updated = profile
        updated.isActive = false
        SharedDefaults.shared.removeLockProfile(id: profile.id)
        SharedDefaults.shared.addLockProfile(updated)
    }

    // Called when a DeviceActivityEvent threshold is reached.
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name,
                                         activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        // Threshold reached means the temporary unlock period is over.
        // Re-apply the shield.
        guard let profileId = UUID(uuidString: activity.rawValue) else { return }
        let profiles = SharedDefaults.shared.getLockProfiles()

        if let profile = profiles.first(where: { $0.id == profileId }) {
            var currentApps = store.shield.applications ?? Set()
            currentApps.formUnion(profile.applicationTokens)
            store.shield.applications = currentApps
        }
    }

    // MARK: - Helpers

    private func reapplyAllShields() {
        let profiles = SharedDefaults.shared.getLockProfiles().filter { $0.isActive }

        var allApps = Set<ApplicationToken>()
        var allCategories = Set<ActivityCategoryToken>()

        for profile in profiles {
            allApps.formUnion(profile.applicationTokens)
            allCategories.formUnion(profile.categoryTokens)
        }

        store.shield.applications = allApps.isEmpty ? nil : allApps
        store.shield.applicationCategories = allCategories.isEmpty ? nil : .specific(allCategories)
    }
}
