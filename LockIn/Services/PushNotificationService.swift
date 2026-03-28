import Foundation
import UserNotifications
import UIKit

/// Manages push notification registration, permission, and token sync with Supabase.
@MainActor
final class PushNotificationService: NSObject, ObservableObject {
    @Published var isPermissionGranted = false
    @Published var deviceToken: String?

    static let shared = PushNotificationService()

    override init() {
        super.init()
        Task { await checkPermission() }
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            isPermissionGranted = granted
            if granted {
                await registerForRemoteNotifications()
            }
            return granted
        } catch {
            #if DEBUG
            print("Push notification permission error: \(error)")
            #endif
            return false
        }
    }

    func checkPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isPermissionGranted = settings.authorizationStatus == .authorized
    }

    // MARK: - Token Registration

    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    /// Called by AppDelegate when APNs returns the device token.
    func didRegisterForRemoteNotifications(withDeviceToken tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = token
        #if DEBUG
        print("📱 APNs token: \(token)")
        #endif

        // Persist token to Supabase
        Task { await savePushToken(token) }
    }

    func didFailToRegisterForRemoteNotifications(withError error: Error) {
        #if DEBUG
        print("❌ Failed to register for push: \(error.localizedDescription)")
        #endif
    }

    // MARK: - Save Token to Supabase

    private func savePushToken(_ token: String) async {
        do {
            guard let userId = try? await supabase.auth.session.user.id else { return }

            try await supabase
                .from("profiles")
                .update(["push_token": token])
                .eq("id", value: userId.uuidString)
                .execute()

            #if DEBUG
            print("✅ Push token saved to Supabase")
            #endif
        } catch {
            #if DEBUG
            print("Failed to save push token: \(error)")
            #endif
        }
    }

    // MARK: - Handle Incoming Notification

    /// Parse notification payload and determine action.
    func handleNotification(_ userInfo: [AnyHashable: Any], completionHandler: (() -> Void)? = nil) {
        guard let type = userInfo["type"] as? String else {
            completionHandler?()
            return
        }

        switch type {
        case "unlock_request":
            // Navigate to Requests tab
            NotificationCenter.default.post(name: .switchToRequestsTab, object: nil)

        case "request_approved":
            // Show approval — could trigger unlock animation
            if let appId = userInfo["app_identifier"] as? String {
                NotificationCenter.default.post(
                    name: .unlockApproved,
                    object: nil,
                    userInfo: ["app_identifier": appId]
                )
            }

        case "request_denied":
            // Show denied state
            NotificationCenter.default.post(name: .switchToRequestsTab, object: nil)

        case "member_joined":
            // Navigate to Pacts tab
            NotificationCenter.default.post(name: .switchToPactsTab, object: nil)

        default:
            break
        }

        completionHandler?()
    }

    // MARK: - Local Notifications (for testing without APNs)

    /// Schedule a local notification (useful for testing and for in-app events).
    func sendLocalNotification(
        title: String,
        body: String,
        userInfo: [String: String] = [:],
        delay: TimeInterval = 0.5
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error {
                print("Local notification error: \(error)")
            }
            #endif
        }
    }
}
