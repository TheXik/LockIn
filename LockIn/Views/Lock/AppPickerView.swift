import SwiftUI
import FamilyControls

struct AppPickerView: View {
    @EnvironmentObject var shieldManager: ShieldManager
    @State private var showActivityPicker = false
    @State private var lockDuration: Double = 30
    @State private var profileName = ""
    @State private var showSaveSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Selected apps display
                    selectedAppsSection

                    // Pick apps button
                    LockInButton("Choose Apps to Lock", icon: "plus.app.fill", style: .secondary) {
                        showActivityPicker = true
                    }

                    // Duration picker
                    durationSection

                    // Lock button
                    if !shieldManager.selectedApps.applicationTokens.isEmpty {
                        VStack(spacing: 12) {
                            LockInButton("Lock In 🔒", icon: "lock.fill") {
                                shieldManager.quickLock(minutes: Int(lockDuration))
                            }

                            LockInButton("Save as Profile", icon: "square.and.arrow.down", style: .ghost) {
                                showSaveSheet = true
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .navigationTitle("Lock Apps")
            .lockInGradientBackground()
            .toolbarColorScheme(.dark, for: .navigationBar)
            .familyActivityPicker(
                isPresented: $showActivityPicker,
                selection: $shieldManager.selectedApps
            )
            .sheet(isPresented: $showSaveSheet) {
                saveProfileSheet
            }
            .animation(.spring(response: 0.4), value: shieldManager.selectedApps.applicationTokens.count)
        }
    }

    // MARK: - Selected Apps
    private var selectedAppsSection: some View {
        VStack(spacing: 16) {
            let count = shieldManager.selectedApps.applicationTokens.count +
                        shieldManager.selectedApps.categoryTokens.count

            if count > 0 {
                HStack {
                    Text("\(count) items selected")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.lockInText)
                    Spacer()
                    Button("Clear") {
                        shieldManager.selectedApps = FamilyActivitySelection()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.lockInDanger)
                }

                AppIconGrid(appTokens: shieldManager.selectedApps.applicationTokens)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 48))
                        .foregroundColor(.lockInTextSecondary)

                    Text("No apps selected")
                        .font(.system(size: 16))
                        .foregroundColor(.lockInTextSecondary)

                    Text("Tap the button below to choose\napps you want to lock.")
                        .font(.system(size: 14))
                        .foregroundColor(.lockInTextSecondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 32)
            }
        }
        .lockInCard()
    }

    // MARK: - Duration
    private var durationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Duration")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.lockInText)
                Spacer()
                Text("\(Int(lockDuration)) min")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.lockInPrimary)
            }

            Slider(value: $lockDuration, in: 5...240, step: 5)
                .tint(.lockInPrimary)

            HStack {
                Text("5 min")
                    .font(.system(size: 12))
                    .foregroundColor(.lockInTextSecondary)
                Spacer()
                Text("4 hours")
                    .font(.system(size: 12))
                    .foregroundColor(.lockInTextSecondary)
            }
        }
        .lockInCard()
    }

    // MARK: - Save Profile Sheet
    private var saveProfileSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                TextField("Profile name", text: $profileName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 20)

                LockInButton("Save Profile", icon: "checkmark") {
                    let profile = LockProfile(
                        name: profileName.isEmpty ? "Untitled" : profileName,
                        applicationTokens: shieldManager.selectedApps.applicationTokens,
                        categoryTokens: shieldManager.selectedApps.categoryTokens,
                        durationMinutes: Int(lockDuration)
                    )
                    SharedDefaults.shared.addLockProfile(profile)
                    showSaveSheet = false
                    profileName = ""
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("Save Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSaveSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
