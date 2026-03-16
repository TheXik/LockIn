import Foundation
import ManagedSettings
import FamilyControls
import DeviceActivity

/// Core service: applies and removes app shields via ManagedSettingsStore.
@MainActor
final class ShieldManager: ObservableObject {
    @Published var selectedApps = FamilyActivitySelection()
    @Published var isLockActive = false
    @Published var activeProfileId: UUID?

    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()

    // MARK: - Shield Control

    /// Apply shields to all selected apps/categories immediately.
    func activateShield() {
        let apps = selectedApps.applicationTokens
        let categories = selectedApps.categoryTokens

        store.shield.applications = apps.isEmpty ? nil : apps
        store.shield.applicationCategories = categories.isEmpty ? nil : .specific(categories)
        store.shield.webDomainCategories = categories.isEmpty ? nil : .specific(categories)

        isLockActive = true
    }

    /// Remove all shields.
    func deactivateShield() {
        store.clearAllSettings()
        isLockActive = false
        activeProfileId = nil
    }

    /// Activate a saved lock profile with a timed schedule.
    func activateProfile(_ profile: LockProfile) {
        // Set app tokens from profile
        store.shield.applications = profile.applicationTokens.isEmpty ? nil : profile.applicationTokens
        store.shield.applicationCategories = profile.categoryTokens.isEmpty ? nil : .specific(profile.categoryTokens)

        // Schedule auto-unlock via DeviceActivity
        let now = Date.now
        let end = Calendar.current.date(byAdding: .minute, value: profile.durationMinutes, to: now) ?? now

        let startComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: now)
        let endComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: end)

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false
        )

        let eventName = DeviceActivityEvent.Name(profile.id.uuidString)
        let event = DeviceActivityEvent(
            applications: profile.applicationTokens,
            threshold: DateComponents(minute: profile.durationMinutes)
        )

        do {
            try center.startMonitoring(
                DeviceActivityName(profile.id.uuidString),
                during: schedule,
                events: [eventName: event]
            )
        } catch {
            print("Failed to start monitoring: \(error)")
        }

        activeProfileId = profile.id
        isLockActive = true

        // Persist active state
        var updated = profile
        updated.isActive = true
        SharedDefaults.shared.removeLockProfile(id: profile.id)
        SharedDefaults.shared.addLockProfile(updated)
    }

    /// Stop monitoring a specific profile.
    func stopProfile(_ profile: LockProfile) {
        center.stopMonitoring([DeviceActivityName(profile.id.uuidString)])
        deactivateShield()

        var updated = profile
        updated.isActive = false
        SharedDefaults.shared.removeLockProfile(id: profile.id)
        SharedDefaults.shared.addLockProfile(updated)
    }

    // MARK: - Quick Lock

    /// Quick lock: shield selected apps for N minutes.
    func quickLock(minutes: Int) {
        activateShield()

        let profile = LockProfile(
            name: "Quick Lock",
            applicationTokens: selectedApps.applicationTokens,
            categoryTokens: selectedApps.categoryTokens,
            durationMinutes: minutes
        )
        activateProfile(profile)
    }
}
