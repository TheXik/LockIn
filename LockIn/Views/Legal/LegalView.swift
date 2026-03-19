import SwiftUI

/// Privacy policy and terms of service displayed in-app and linked from App Store.
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    section("What we collect") {
                        bullet("Your Apple ID (for authentication only)")
                        bullet("Display name and avatar emoji you choose")
                        bullet("Push notification token (to send unlock request alerts)")
                        bullet("Lock session data (which apps you blocked, when)")
                    }

                    section("What we DON'T collect") {
                        bullet("Your actual app usage data — that stays on your device")
                        bullet("Your contacts or phone number")
                        bullet("Any data from blocked apps")
                        bullet("Location, photos, or messages")
                    }

                    section("How Screen Time works") {
                        Text("LockIn uses Apple's FamilyControls framework to block apps. The actual blocking happens at the OS level on your device. We never see which specific apps you're using — we only see anonymous app tokens that Apple provides.")
                            .font(.system(size: 14))
                            .foregroundColor(.lockInTextSecondary)
                            .lineSpacing(4)
                    }

                    section("Data storage") {
                        Text("Your data is stored securely on Supabase (cloud infrastructure) with row-level security. Each user can only access their own data and data shared within their pacts. We use industry-standard encryption in transit and at rest.")
                            .font(.system(size: 14))
                            .foregroundColor(.lockInTextSecondary)
                            .lineSpacing(4)
                    }

                    section("Data deletion") {
                        Text("You can delete your account and all associated data at any time from Settings. When you leave a pact, your membership data is immediately removed. When you delete your account, all your data is permanently deleted within 30 days.")
                            .font(.system(size: 14))
                            .foregroundColor(.lockInTextSecondary)
                            .lineSpacing(4)
                    }

                    section("Third parties") {
                        bullet("Apple Sign In — authentication")
                        bullet("Supabase — backend database and real-time sync")
                        bullet("Apple Push Notification Service — unlock request alerts")
                        bullet("No analytics trackers, no ad networks, no data brokers")
                    }

                    Text("Last updated: March 2026")
                        .font(.system(size: 12))
                        .foregroundColor(.lockInTextTertiary)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .lockInScreenBackground()
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.lockInPrimary)
                }
            }
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.lockInTextTertiary)
                .tracking(1.5)

            content()
        }
        .lockInCard()
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .foregroundColor(.lockInPrimary)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.lockInTextSecondary)
                .lineSpacing(2)
        }
    }
}

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    section("The deal") {
                        Text("LockIn helps you stay focused by letting your friends hold you accountable. You form pacts with people you trust, lock distracting apps, and your pact members approve or deny unlock requests.")
                            .font(.system(size: 14))
                            .foregroundColor(.lockInTextSecondary)
                            .lineSpacing(4)
                    }

                    section("Your responsibilities") {
                        bullet("Only form pacts with people you trust")
                        bullet("Don't abuse the approve/deny system")
                        bullet("Keep your app updated for the best experience")
                        bullet("You're responsible for managing your own screen time goals")
                    }

                    section("Our responsibilities") {
                        bullet("Keep your data secure and private")
                        bullet("Don't sell your data to anyone, ever")
                        bullet("Maintain the service and fix bugs")
                        bullet("Be transparent about changes")
                    }

                    section("Limitations") {
                        Text("LockIn is a tool to support your goals, not a guarantee. App blocking depends on Apple's FamilyControls framework and your device settings. We can't prevent all workarounds or guarantee 100% uptime.")
                            .font(.system(size: 14))
                            .foregroundColor(.lockInTextSecondary)
                            .lineSpacing(4)
                    }

                    Text("Last updated: March 2026")
                        .font(.system(size: 12))
                        .foregroundColor(.lockInTextTertiary)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .lockInScreenBackground()
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.lockInPrimary)
                }
            }
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.lockInTextTertiary)
                .tracking(1.5)

            content()
        }
        .lockInCard()
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .foregroundColor(.lockInPrimary)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.lockInTextSecondary)
                .lineSpacing(2)
        }
    }
}
