import Foundation
import ManagedSettings
import FamilyControls
import DeviceActivity

/// Core service: applies and removes app shields via ManagedSettingsStore.
@MainActor
final class ShieldManager: ObservableObject {
    @Published var selectedApps = FamilyActivitySelection()
    @Published var isLockActive = false

    private let store = ManagedSettingsStore()

    // MARK: - Shield Control

    /// Apply shields to all selected apps/categories.
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
    }

    /// Remove shield for a single app token (after unlock approved).
    func unlockSingleApp(_ token: ApplicationToken) {
        store.shield.applications?.remove(token)
        if store.shield.applications?.isEmpty == true {
            store.shield.applications = nil
            isLockActive = false
        }
    }
}
