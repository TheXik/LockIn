import Foundation

enum AppConstants {
    static let appGroupIdentifier = "group.com.lockin.app"
    static let guardianPinKey = "guardianPin"
    static let lockedAppsKey = "lockedApps"
    static let lockProfilesKey = "lockProfiles"
    static let isGuardianModeKey = "isGuardianMode"
    static let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    static let userModeKey = "userMode"

    enum UserMode: String, Codable {
        case selfLock     // user locks themselves
        case guardian     // guardian locks the device
    }
}
