import DeviceActivity
import ManagedSettings
import Foundation

/// Monitors device activity. Currently a placeholder — lock management
/// is handled by the main app + Supabase in the pact approval flow.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Future: re-apply shields based on schedule from Supabase
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name,
                                         activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        // Future: enforce daily time limits
    }
}
