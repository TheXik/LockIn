import Foundation
import ManagedSettings
import FamilyControls
import DeviceActivity

/// Core service: applies and removes app shields via ManagedSettingsStore.
/// Persists lock state + selected apps via App Group UserDefaults so state survives restarts.
@MainActor
final class ShieldManager: ObservableObject {
    @Published var selectedApps = FamilyActivitySelection() {
        didSet { persistSelection() }
    }
    @Published var isLockActive = false {
        didSet { persistLockState() }
    }

    /// Timestamp when the current lock session started.
    @Published var lockStartedAt: Date?

    private let store = ManagedSettingsStore()

    /// Shared UserDefaults for App Group (accessible from extensions too).
    private let defaults: UserDefaults

    private let kIsLockActive = "lockin.isLockActive"
    private let kLockStartedAt = "lockin.lockStartedAt"
    private let kSelectedApps = "lockin.selectedApps"

    init() {
        defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) ?? .standard
        restoreState()
    }

    // MARK: - Shield Control

    /// Apply shields to all selected apps/categories.
    func activateShield() {
        let apps = selectedApps.applicationTokens
        let categories = selectedApps.categoryTokens

        store.shield.applications = apps.isEmpty ? nil : apps
        store.shield.applicationCategories = categories.isEmpty ? nil : .specific(categories)
        store.shield.webDomainCategories = categories.isEmpty ? nil : .specific(categories)

        lockStartedAt = Date()
        isLockActive = true
    }

    /// Remove all shields.
    func deactivateShield() {
        store.clearAllSettings()
        lockStartedAt = nil
        isLockActive = false
    }

    /// Remove shield for a single app token (after unlock approved).
    func unlockSingleApp(_ token: ApplicationToken) {
        store.shield.applications?.remove(token)
        if store.shield.applications?.isEmpty == true {
            store.shield.applications = nil
            lockStartedAt = nil
            isLockActive = false
        }
    }

    // MARK: - Persistence

    private func persistLockState() {
        defaults.set(isLockActive, forKey: kIsLockActive)
        defaults.set(lockStartedAt?.timeIntervalSince1970, forKey: kLockStartedAt)
    }

    private func persistSelection() {
        // FamilyActivitySelection is Codable — encode and save
        if let data = try? JSONEncoder().encode(selectedApps) {
            defaults.set(data, forKey: kSelectedApps)
        }
    }

    private func restoreState() {
        // Restore lock active state
        let wasActive = defaults.bool(forKey: kIsLockActive)

        // Restore selected apps
        if let data = defaults.data(forKey: kSelectedApps),
           let restored = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selectedApps = restored
        }

        // Restore lock started timestamp
        let startedEpoch = defaults.double(forKey: kLockStartedAt)
        if startedEpoch > 0 {
            lockStartedAt = Date(timeIntervalSince1970: startedEpoch)
        }

        // Re-apply shields if they were active
        if wasActive && !selectedApps.applicationTokens.isEmpty {
            activateShield()
        }
    }

    // MARK: - Computed

    /// How long the current lock has been active.
    var lockDuration: TimeInterval? {
        guard let start = lockStartedAt, isLockActive else { return nil }
        return Date().timeIntervalSince(start)
    }

    /// Formatted lock duration string (e.g. "2h 15m").
    var lockDurationFormatted: String? {
        guard let duration = lockDuration else { return nil }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
