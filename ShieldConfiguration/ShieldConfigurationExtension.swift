import ManagedSettingsUI
import ManagedSettings
import UIKit

/// Customizes the shield overlay shown when a blocked app is opened.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfig(
            title: "This app is locked 🔒",
            subtitle: "Stay focused. You've got this.",
            primaryButton: "I Need This App",
            secondaryButton: "Stay Locked In"
        )
    }

    override func configuration(shielding application: Application,
                                in category: ActivityCategory) -> ShieldConfiguration {
        makeConfig(
            title: "This category is locked 🔒",
            subtitle: "Focus time. Come back later.",
            primaryButton: "Open Anyway",
            secondaryButton: "Stay Locked In"
        )
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfig(
            title: "This site is locked 🔒",
            subtitle: "Block the scroll. Lock in.",
            primaryButton: "I Need This Site",
            secondaryButton: "Stay Locked In"
        )
    }

    override func configuration(shielding webDomain: WebDomain,
                                in category: ActivityCategory) -> ShieldConfiguration {
        makeConfig(
            title: "This category is locked 🔒",
            subtitle: "Focus time. Come back later.",
            primaryButton: "Open Anyway",
            secondaryButton: "Stay Locked In"
        )
    }

    // MARK: - Helpers

    private func makeConfig(
        title: String,
        subtitle: String,
        primaryButton: String,
        secondaryButton: String
    ) -> ShieldConfiguration {
        let purple = UIColor(red: 108/255, green: 92/255, blue: 231/255, alpha: 1)  // #6C5CE7
        let darkBg = UIColor(red: 15/255, green: 15/255, blue: 26/255, alpha: 1)    // #0F0F1A

        return ShieldConfiguration(
            backgroundColor: darkBg,
            title: ShieldConfiguration.Label(text: title, color: .white),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: .lightGray),
            primaryButtonLabel: ShieldConfiguration.Label(text: primaryButton, color: .white),
            primaryButtonBackgroundColor: purple,
            secondaryButtonLabel: ShieldConfiguration.Label(text: secondaryButton, color: .lightGray)
        )
    }
}
