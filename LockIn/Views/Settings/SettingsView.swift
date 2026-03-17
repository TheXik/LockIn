import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var shieldManager: ShieldManager
    @State private var showResetConfirmation = false
    @State private var editingName = false
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            List {
                // Profile
                Section {
                    HStack(spacing: 16) {
                        Text(authService.currentUser?.avatarEmoji ?? "🔥")
                            .font(.system(size: 36))
                            .frame(width: 50, height: 50)
                            .background(Color.lockInSurfaceLight)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(authService.currentUser?.displayName ?? "User")
                                .font(.system(size: 17, weight: .semibold))

                            Text("Signed in with Apple")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button("Edit") { editingName = true }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.lockInPrimary)
                    }
                    .padding(.vertical, 4)
                }

                // Screen Time
                Section("Screen Time") {
                    Button {
                        if let url = URL(string: "App-prefs:SCREEN_TIME") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Screen Time Settings", systemImage: "hourglass")
                    }
                }

                // Emergency
                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Remove All Locks", systemImage: "lock.open.fill")
                            .foregroundColor(.lockInDanger)
                    }
                } header: {
                    Text("Emergency")
                } footer: {
                    Text("This will unlock all blocked apps. Your pact members will be notified.")
                }

                // Sign out
                Section {
                    Button(role: .destructive) {
                        Task { await authService.signOut() }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } footer: {
                    Text("LockIn v1.0 — Accountability, together.")
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                }
            }
            .navigationTitle("Settings")
            .alert("Remove All Locks?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Remove All", role: .destructive) {
                    shieldManager.deactivateShield()
                }
            } message: {
                Text("This will unlock all blocked apps immediately.")
            }
            .alert("Edit Name", isPresented: $editingName) {
                TextField("Your name", text: $newName)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    Task { await authService.updateDisplayName(newName) }
                }
            }
        }
    }
}
