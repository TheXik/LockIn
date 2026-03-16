import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var shieldManager: ShieldManager
    @State private var showResetConfirmation = false
    @State private var showGuardianSetup = false
    @State private var showGuardianPin = false

    private let userMode = SharedDefaults.shared.getUserMode()

    var body: some View {
        NavigationStack {
            List {
                // Account
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.lockInPrimary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Signed in with Apple")
                                .font(.system(size: 16, weight: .medium))
                            Text("Manage your account")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Mode
                Section("Mode") {
                    HStack {
                        Label(
                            userMode == .guardian ? "Guardian Mode" : "Self Lock",
                            systemImage: userMode == .guardian ? "person.2.fill" : "person.fill"
                        )
                        Spacer()
                        Text(userMode == .guardian ? "Active" : "Active")
                            .font(.system(size: 13))
                            .foregroundColor(.lockInPrimary)
                    }

                    if userMode == .guardian {
                        Button {
                            showGuardianPin = true
                        } label: {
                            Label("Change Guardian PIN", systemImage: "lock.rotation")
                        }
                    }
                }

                // Profiles
                Section("Lock Profiles") {
                    let profiles = SharedDefaults.shared.getLockProfiles()

                    if profiles.isEmpty {
                        Text("No saved profiles")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(profiles) { profile in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(profile.name)
                                        .font(.system(size: 15, weight: .medium))
                                    Text("\(profile.applicationTokens.count) apps · \(profile.durationMinutes) min")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if profile.isActive {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(.lockInSuccess)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                SharedDefaults.shared.removeLockProfile(id: profiles[index].id)
                            }
                        }
                    }
                }

                // Screen Time
                Section("Screen Time") {
                    Button {
                        if let url = URL(string: "App-prefs:SCREEN_TIME") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open Screen Time Settings", systemImage: "hourglass")
                    }
                }

                // Danger zone
                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Remove All Shields", systemImage: "trash")
                            .foregroundColor(.lockInDanger)
                    }
                } footer: {
                    Text("LockIn v1.0 — Stay focused. 🔒")
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                }
            }
            .navigationTitle("Settings")
            .alert("Remove All Shields?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    shieldManager.deactivateShield()
                }
            } message: {
                Text("This will unlock all currently blocked apps.")
            }
            .sheet(isPresented: $showGuardianSetup) {
                GuardianSetupView()
                    .environmentObject(shieldManager)
            }
            .sheet(isPresented: $showGuardianPin) {
                GuardianPinView {
                    showGuardianPin = false
                    showGuardianSetup = true
                }
            }
        }
    }
}
