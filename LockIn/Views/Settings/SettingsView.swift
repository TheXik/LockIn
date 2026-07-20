import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var shieldManager: ShieldManager
    @EnvironmentObject var screenTimeAuth: ScreenTimeAuthService
    @EnvironmentObject var pushService: PushNotificationService
    @EnvironmentObject var streakService: StreakService
    @State private var showResetConfirmation = false
    @State private var showSignOutConfirmation = false
    @State private var showPrivacyPolicy = false
    @State private var showTerms = false
    @State private var editingName = false
    @State private var newName = ""
    @State private var showDeleteSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LKSpace.xl) {
                    header
                    profileSection
                    streakStatsSection
                    notificationSection
                    screenTimeSection
                    dangerSection
                    legalSection
                    accountSection

                    Text("LockIn v1.0")
                        .font(.lkCaption)
                        .foregroundColor(.lockInTextTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, LKSpace.sm)
                }
                .padding(.horizontal, LKSpace.xl)
                .padding(.top, LKSpace.sm)
                .padding(.bottom, LKSpace.xxxl)
            }
            .navigationBarHidden(true)
            .lockInScreenBackground()
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Edit Name", isPresented: $editingName) {
                TextField("Your name", text: $newName)
                    .onChange(of: newName) { _ in
                        if newName.count > 100 { newName = String(newName.prefix(100)) }
                    }
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    Task { await authService.updateDisplayName(trimmed) }
                }
            }
            .alert("Remove All Locks?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Remove All", role: .destructive) {
                    shieldManager.deactivateShield(userId: authService.currentUser?.id)
                }
            } message: {
                Text("This will unlock all blocked apps immediately. Your pact members will be notified.")
            }
            .alert("Sign Out?", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task { await authService.signOut() }
                }
            } message: {
                Text("You'll need to sign in again to use LockIn.")
            }
        }
    }

    // MARK: - Header — editorial, left-aligned, type-led (not a stock nav title).
    private var header: some View {
        VStack(alignment: .leading, spacing: LKSpace.xs) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LockInGradient.ember)
                Text("YOUR HEARTH")
                    .font(.lkMicro)
                    .tracking(2)
                    .foregroundColor(.lockInTextTertiary)
            }

            Text("Settings")
                .font(.system(size: 40, weight: .black))
                .tracking(-1.2)
                .foregroundColor(.lockInText)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .padding(.top, LKSpace.sm)
    }

    // MARK: - Section label
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.lkMicro)
            .tracking(1.6)
            .foregroundColor(.lockInTextTertiary)
    }

    // MARK: - Profile
    private var profileSection: some View {
        HStack(spacing: LKSpace.lg) {
            let emoji = authService.currentUser?.avatarEmoji ?? "🔥"

            Text(emoji)
                .font(.system(size: 26))
                .frame(width: 52, height: 52)
                .background(LockInGradient.subtle)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.lockInHairline, lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                Text(authService.currentUser?.displayName ?? "User")
                    .font(.lkHeadline)
                    .foregroundColor(.lockInText)

                Text("Signed in with Apple")
                    .font(.lkCaption)
                    .foregroundColor(.lockInTextSecondary)
            }

            Spacer()

            Button {
                newName = authService.currentUser?.displayName ?? ""
                editingName = true
            } label: {
                Text("Edit")
                    .font(.lkCallout)
                    .foregroundColor(.lockInPrimary)
                    .padding(.horizontal, LKSpace.md)
                    .padding(.vertical, 7)
                    .background(LockInGradient.subtle)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.lockInPrimary.opacity(0.35), lineWidth: 1))
            }
            .accessibilityLabel("Edit name")
        }
        .lockInCard()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Streak Stats
    private var streakStatsSection: some View {
        VStack(alignment: .leading, spacing: LKSpace.lg) {
            sectionLabel("YOUR STATS")

            HStack(spacing: 0) {
                statColumn(
                    value: streakService.currentStreak,
                    label: "Current\nStreak",
                    color: .lockInPrimary,
                    lit: streakService.currentStreak > 0
                )

                statDivider

                statColumn(
                    value: streakService.longestStreak,
                    label: "Longest\nStreak",
                    color: .lockInSecondary,
                    lit: false
                )

                statDivider

                statColumn(
                    value: streakService.totalLockDays,
                    label: "Total\nDays",
                    color: .lockInSuccess,
                    lit: false
                )
            }
        }
        .lockInCard()
    }

    private func statColumn(value: Int, label: String, color: Color, lit: Bool) -> some View {
        VStack(spacing: LKSpace.xs) {
            Text("\(value)")
                .font(.lkMono(30, .heavy))
                .foregroundColor(color)
                // The one lit element on this screen: a live streak reads as ember.
                .modifier(ConditionalGlow(active: lit))
            Text(label)
                .font(.lkMicro)
                .foregroundColor(.lockInTextTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.lockInHairline)
            .frame(width: 1, height: 40)
    }

    // MARK: - Notifications
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: LKSpace.lg) {
            sectionLabel("NOTIFICATIONS")

            statusRow(
                icon: pushService.isPermissionGranted ? "bell.badge.fill" : "bell.slash",
                tint: pushService.isPermissionGranted ? .lockInSuccess : .lockInWarning,
                title: pushService.isPermissionGranted ? "Push Notifications Active" : "Notifications Disabled",
                subtitle: pushService.isPermissionGranted ? "You'll be notified when squad members need you" : "Enable to get unlock request alerts"
            )

            if !pushService.isPermissionGranted {
                LockInButton("Enable Notifications", icon: "bell.badge", style: .secondary) {
                    Task { _ = await pushService.requestPermission() }
                }
            }
        }
        .lockInCard()
    }

    // MARK: - Screen Time
    private var screenTimeSection: some View {
        VStack(alignment: .leading, spacing: LKSpace.lg) {
            sectionLabel("SCREEN TIME")

            statusRow(
                icon: statusIcon,
                tint: statusColor,
                title: statusTitle,
                subtitle: statusSubtitle
            )

            if case .notDetermined = screenTimeAuth.authorizationStatus {
                LockInButton("Allow Access", icon: "checkmark.shield", style: .secondary) {
                    Task { await screenTimeAuth.requestAuthorization() }
                }
            }
        }
        .lockInCard()
    }

    // A shared status row — a live badge + two lines of state, left-aligned.
    private func statusRow(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: LKSpace.md) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.lkBodyStrong)
                    .foregroundColor(.lockInText)
                Text(subtitle)
                    .font(.lkCaption)
                    .foregroundColor(.lockInTextSecondary)
            }
            Spacer()
        }
    }

    private var statusIcon: String {
        switch screenTimeAuth.authorizationStatus {
        case .approved: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .notDetermined: return "questionmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        switch screenTimeAuth.authorizationStatus {
        case .approved: return .lockInSuccess
        case .denied, .error: return .lockInDanger
        case .notDetermined: return .lockInWarning
        }
    }

    private var statusTitle: String {
        switch screenTimeAuth.authorizationStatus {
        case .approved: return "Screen Time Active"
        case .denied: return "Access Denied"
        case .notDetermined: return "Not Set Up"
        case .error(let msg): return "Error: \(msg)"
        }
    }

    private var statusSubtitle: String {
        switch screenTimeAuth.authorizationStatus {
        case .approved: return "LockIn can manage your apps"
        case .denied: return "Go to Settings > Screen Time to enable"
        case .notDetermined: return "Tap below to enable app blocking"
        case .error: return "Try again or restart the app"
        }
    }

    // MARK: - Danger Zone
    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: LKSpace.lg) {
            sectionLabel("DANGER ZONE")

            Button { showResetConfirmation = true } label: {
                HStack(spacing: LKSpace.md) {
                    ZStack {
                        Circle()
                            .fill(Color.lockInDanger.opacity(0.14))
                            .frame(width: 40, height: 40)
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.lockInDanger)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Remove All Locks")
                            .font(.lkBodyStrong)
                            .foregroundColor(.lockInDanger)
                        Text("Pact members will be notified")
                            .font(.lkCaption)
                            .foregroundColor(.lockInTextSecondary)
                    }
                    Spacer()
                }
            }

            Rectangle()
                .fill(Color.lockInHairline)
                .frame(height: 1)

            Button { showDeleteSheet = true } label: {
                HStack(spacing: LKSpace.md) {
                    ZStack {
                        Circle()
                            .fill(Color.lockInDanger.opacity(0.14))
                            .frame(width: 40, height: 40)
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.lockInDanger)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delete Account")
                            .font(.lkBodyStrong)
                            .foregroundColor(.lockInDanger)
                        Text("Permanently erases you and your data")
                            .font(.lkCaption)
                            .foregroundColor(.lockInTextSecondary)
                    }
                    Spacer()
                }
            }
        }
        .lockInCard()
        .overlay(
            RoundedRectangle(cornerRadius: LKRadius.lg, style: .continuous)
                .stroke(Color.lockInDanger.opacity(0.20), lineWidth: 1)
        )
        .sheet(isPresented: $showDeleteSheet) {
            DeleteAccountSheet().environmentObject(authService)
        }
    }

    // MARK: - Legal
    private var legalSection: some View {
        VStack(alignment: .leading, spacing: LKSpace.md) {
            sectionLabel("LEGAL")

            linkRow(icon: "hand.raised.fill", title: "Privacy Policy") {
                showPrivacyPolicy = true
            }

            Rectangle()
                .fill(Color.lockInHairline)
                .frame(height: 1)

            linkRow(icon: "doc.text.fill", title: "Terms of Service") {
                showTerms = true
            }
        }
        .lockInCard()
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showTerms) {
            TermsOfServiceView()
        }
    }

    private func linkRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: LKSpace.md) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.lockInTextSecondary)
                    .frame(width: 24)
                Text(title)
                    .font(.lkCallout)
                    .foregroundColor(.lockInText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.lockInTextTertiary)
            }
        }
    }

    // MARK: - Account
    private var accountSection: some View {
        Button { showSignOutConfirmation = true } label: {
            HStack(spacing: LKSpace.md) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.lockInTextSecondary)
                    .frame(width: 24)

                Text("Sign Out")
                    .font(.lkCallout)
                    .foregroundColor(.lockInTextSecondary)

                Spacer()
            }
        }
        .lockInCard()
    }
}

// MARK: - Conditional glow

/// Applies the flame glow only when active — keeps the "one lit element" rule
/// honest and respects Reduce Motion by never animating the glow in.
private struct ConditionalGlow: ViewModifier {
    let active: Bool
    @ViewBuilder
    func body(content: Content) -> some View {
        if active {
            content.lockInGlow(.lockInGlow, radius: 16, intensity: 0.55)
        } else {
            content
        }
    }
}

// MARK: - Delete Account

/// Irreversible account deletion with type-to-confirm friction (App Store 5.1.1(v)).
private struct DeleteAccountSheet: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var confirmText = ""
    @State private var isDeleting = false
    @State private var errorMessage: String?

    private var canDelete: Bool {
        confirmText.trimmingCharacters(in: .whitespaces).uppercased() == "DELETE"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LKSpace.lg) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(.lockInDanger)

                    Text("This can't be undone.")
                        .font(.lkTitle)
                        .foregroundColor(.lockInText)

                    Text("Deleting your account permanently erases your profile, your pact memberships, your lock history, and your unlock requests. Pacts where you're the only member are dissolved; where others remain, they keep the pact.")
                        .font(.lkBody)
                        .foregroundColor(.lockInTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: LKSpace.sm) {
                        Text("TYPE \"DELETE\" TO CONFIRM")
                            .font(.lkMicro)
                            .tracking(1.5)
                            .foregroundColor(.lockInTextTertiary)

                        TextField("DELETE", text: $confirmText)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.lkBodyStrong)
                            .foregroundColor(.lockInText)
                            .padding(14)
                            .background(Color.lockInSurfaceLight)
                            .clipShape(RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous))
                            .lockInHairlineStroke(LKRadius.md)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.lkCaption)
                            .foregroundColor(.lockInDanger)
                    }
                }
                .padding(20)
            }
            .lockInScreenBackground()
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.lockInTextSecondary)
                        .disabled(isDeleting)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(role: .destructive) {
                    Task { await performDelete() }
                } label: {
                    HStack(spacing: LKSpace.sm) {
                        if isDeleting { ProgressView().tint(.white) }
                        Text(isDeleting ? "Deleting…" : "Delete My Account")
                            .font(.lkBodyStrong)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background((canDelete && !isDeleting) ? Color.lockInDanger : Color.lockInSurfaceHi)
                    .foregroundColor((canDelete && !isDeleting) ? .white : .lockInTextTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous))
                }
                .disabled(!canDelete || isDeleting)
                .padding(20)
            }
        }
        .interactiveDismissDisabled(isDeleting)
    }

    private func performDelete() async {
        isDeleting = true
        errorMessage = nil
        do {
            try await authService.deleteAccount()
            // Success: the app root flips to AuthView as isAuthenticated goes false.
            dismiss()
        } catch {
            errorMessage = "Couldn't delete your account. Check your connection and try again."
            isDeleting = false
        }
    }
}
