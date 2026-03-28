import Foundation

enum AppConstants {
    static let appGroupIdentifier = "group.com.lukashellesch.lockin"
    static let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    static let lockProfilesKey = "lockProfiles"

    // Supabase — loaded from Secrets.xcconfig via Info.plist
    static var supabaseURL: String {
        Bundle.main.infoDictionary?["SUPABASE_URL"] as? String ?? ""
    }
    static var supabaseAnonKey: String {
        Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String ?? ""
    }
}
