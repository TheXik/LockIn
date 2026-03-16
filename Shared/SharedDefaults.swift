import Foundation
import ManagedSettings
import FamilyControls

/// Shared UserDefaults store accessible by main app and all extensions via App Group.
final class SharedDefaults {
    static let shared = SharedDefaults()

    private let defaults: UserDefaults

    private init() {
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) else {
            fatalError("App Group \(AppConstants.appGroupIdentifier) not configured")
        }
        self.defaults = defaults
    }

    // MARK: - Lock Profiles

    func saveLockProfiles(_ profiles: [LockProfile]) {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        defaults.set(data, forKey: AppConstants.lockProfilesKey)
    }

    func getLockProfiles() -> [LockProfile] {
        guard let data = defaults.data(forKey: AppConstants.lockProfilesKey),
              let profiles = try? JSONDecoder().decode([LockProfile].self, from: data)
        else { return [] }
        return profiles
    }

    func addLockProfile(_ profile: LockProfile) {
        var profiles = getLockProfiles()
        profiles.append(profile)
        saveLockProfiles(profiles)
    }

    func removeLockProfile(id: UUID) {
        var profiles = getLockProfiles()
        profiles.removeAll { $0.id == id }
        saveLockProfiles(profiles)
    }

    func getLockProfile(id: UUID) -> LockProfile? {
        getLockProfiles().first { $0.id == id }
    }

    // MARK: - Guardian PIN

    func setGuardianPin(_ pin: String) {
        defaults.set(pin, forKey: AppConstants.guardianPinKey)
    }

    func getGuardianPin() -> String? {
        defaults.string(forKey: AppConstants.guardianPinKey)
    }

    // MARK: - User Mode

    func setUserMode(_ mode: AppConstants.UserMode) {
        defaults.set(mode.rawValue, forKey: AppConstants.userModeKey)
    }

    func getUserMode() -> AppConstants.UserMode {
        guard let raw = defaults.string(forKey: AppConstants.userModeKey),
              let mode = AppConstants.UserMode(rawValue: raw)
        else { return .selfLock }
        return mode
    }

    // MARK: - Onboarding

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: AppConstants.hasCompletedOnboardingKey) }
        set { defaults.set(newValue, forKey: AppConstants.hasCompletedOnboardingKey) }
    }
}
