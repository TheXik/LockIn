import ManagedSettingsUI
import ManagedSettings
import UIKit

/// Customizes the shield overlay — black/yellow LockIn brand with motivational copy.
/// Reads lock context from App Group UserDefaults for personalized messages.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private let appGroupID = "group.com.lukashellesch.lockin"

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfig(for: .app)
    }

    override func configuration(shielding application: Application,
                                in category: ActivityCategory) -> ShieldConfiguration {
        makeConfig(for: .category)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfig(for: .web)
    }

    override func configuration(shielding webDomain: WebDomain,
                                in category: ActivityCategory) -> ShieldConfiguration {
        makeConfig(for: .category)
    }

    // MARK: - Config Builder

    private enum ShieldType {
        case app, category, web
    }

    private func makeConfig(for type: ShieldType) -> ShieldConfiguration {
        let yellow = UIColor(red: 255/255, green: 214/255, blue: 10/255, alpha: 1)  // #FFD60A
        let black = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        let darkGray = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)

        let title = shieldTitle(for: type)
        let subtitle = shieldSubtitle()

        return ShieldConfiguration(
            backgroundColor: black,
            title: ShieldConfiguration.Label(text: title, color: .white),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: darkGray),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Open LockIn", color: black),
            primaryButtonBackgroundColor: yellow,
            secondaryButtonLabel: ShieldConfiguration.Label(text: "Stay focused 💪", color: darkGray)
        )
    }

    // MARK: - Dynamic Copy

    private func shieldTitle(for type: ShieldType) -> String {
        let lockDuration = readLockDuration()

        switch type {
        case .app:
            if let duration = lockDuration {
                return "🔥 Locked for \(duration)"
            }
            return "🔥 This app is locked"
        case .category:
            return "🔥 This category is locked"
        case .web:
            return "🔥 This site is locked"
        }
    }

    private func shieldSubtitle() -> String {
        // Rotate through motivational messages
        let messages = [
            "Your squad is counting on you. Stay focused.",
            "You locked this for a reason. Remember why.",
            "Open LockIn to request an unlock from your pact.",
            "Every minute focused adds to your streak.",
            "Your future self will thank you.",
            "Don't break the chain. Your squad can see.",
        ]

        // Use the current minute to cycle messages (deterministic, changes every minute)
        let minute = Calendar.current.component(.minute, from: Date())
        return messages[minute % messages.count]
    }

    // MARK: - App Group Data

    private func readLockDuration() -> String? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        let startedEpoch = defaults.double(forKey: "lockin.lockStartedAt")
        guard startedEpoch > 0 else { return nil }

        let start = Date(timeIntervalSince1970: startedEpoch)
        let duration = Date().timeIntervalSince(start)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
