import ManagedSettingsUI
import ManagedSettings
import UIKit

/// Customizes the shield overlay — black/yellow to match LockIn brand.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfig(
            title: "This app is locked 🔒",
            subtitle: "Open LockIn to request unlock from your pact.",
            primaryButton: "Request Unlock",
            secondaryButton: "Stay Locked In"
        )
    }

    override func configuration(shielding application: Application,
                                in category: ActivityCategory) -> ShieldConfiguration {
        makeConfig(
            title: "This category is locked 🔒",
            subtitle: "Your accountability partner has your back.",
            primaryButton: "Request Unlock",
            secondaryButton: "Stay Locked In"
        )
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfig(
            title: "This site is locked 🔒",
            subtitle: "Open LockIn to request unlock from your pact.",
            primaryButton: "Request Unlock",
            secondaryButton: "Stay Locked In"
        )
    }

    override func configuration(shielding webDomain: WebDomain,
                                in category: ActivityCategory) -> ShieldConfiguration {
        makeConfig(
            title: "This category is locked 🔒",
            subtitle: "Your accountability partner has your back.",
            primaryButton: "Request Unlock",
            secondaryButton: "Stay Locked In"
        )
    }

    private func makeConfig(
        title: String,
        subtitle: String,
        primaryButton: String,
        secondaryButton: String
    ) -> ShieldConfiguration {
        let yellow = UIColor(red: 255/255, green: 214/255, blue: 10/255, alpha: 1)  // #FFD60A
        let black = UIColor(red: 0, green: 0, blue: 0, alpha: 1)

        return ShieldConfiguration(
            backgroundColor: black,
            title: ShieldConfiguration.Label(text: title, color: .white),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: .lightGray),
            primaryButtonLabel: ShieldConfiguration.Label(text: primaryButton, color: black),
            primaryButtonBackgroundColor: yellow,
            secondaryButtonLabel: ShieldConfiguration.Label(text: secondaryButton, color: .lightGray)
        )
    }
}
