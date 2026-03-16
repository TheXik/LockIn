import SwiftUI

/// Guardian sets a custom PIN and selects apps to lock.
struct GuardianSetupView: View {
    @EnvironmentObject var shieldManager: ShieldManager
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var step: SetupStep = .createPin
    @State private var pinError: String?
    @State private var showActivityPicker = false
    @State private var lockDuration: Double = 60

    enum SetupStep {
        case createPin
        case confirmPin
        case selectApps
        case setDuration
        case review
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                switch step {
                case .createPin:
                    pinEntryView(
                        title: "Create Guardian PIN",
                        subtitle: "This PIN will be required to unlock apps.",
                        binding: $pin
                    ) {
                        if pin.count == 4 {
                            step = .confirmPin
                        }
                    }

                case .confirmPin:
                    pinEntryView(
                        title: "Confirm PIN",
                        subtitle: "Enter the same PIN again.",
                        binding: $confirmPin
                    ) {
                        if confirmPin == pin {
                            SharedDefaults.shared.setGuardianPin(pin)
                            step = .selectApps
                        } else {
                            pinError = "PINs don't match. Try again."
                            confirmPin = ""
                        }
                    }

                case .selectApps:
                    appSelectionView

                case .setDuration:
                    durationView

                case .review:
                    reviewView
                }
            }
            .padding(.horizontal, 20)
            .lockInGradientBackground()
            .navigationTitle("Guardian Setup")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - PIN Entry
    private func pinEntryView(
        title: String,
        subtitle: String,
        binding: Binding<String>,
        onComplete: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 56))
                .foregroundColor(.lockInPrimary)

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.lockInText)

                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundColor(.lockInTextSecondary)
            }

            // PIN dots
            HStack(spacing: 20) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(i < binding.wrappedValue.count ? Color.lockInPrimary : Color.lockInSurfaceLight)
                        .frame(width: 20, height: 20)
                }
            }

            if let error = pinError {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.lockInDanger)
            }

            // Hidden text field for keyboard input
            SecureField("", text: binding)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: binding.wrappedValue) { newValue in
                    if newValue.count > 4 {
                        binding.wrappedValue = String(newValue.prefix(4))
                    }
                    if newValue.count == 4 {
                        onComplete()
                    }
                }

            Spacer()
        }
    }

    // MARK: - App Selection
    private var appSelectionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "app.badge.checkmark.fill")
                .font(.system(size: 56))
                .foregroundColor(.lockInPrimary)

            Text("Select Apps to Lock")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.lockInText)

            LockInButton("Choose Apps", icon: "plus.app.fill") {
                showActivityPicker = true
            }

            if !shieldManager.selectedApps.applicationTokens.isEmpty {
                AppIconGrid(appTokens: shieldManager.selectedApps.applicationTokens)

                LockInButton("Continue", icon: "arrow.right") {
                    step = .setDuration
                }
            }

            Spacer()
        }
        .familyActivityPicker(
            isPresented: $showActivityPicker,
            selection: $shieldManager.selectedApps
        )
    }

    // MARK: - Duration
    private var durationView: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("How long?")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.lockInText)

            Text("\(Int(lockDuration)) minutes")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.lockInPrimary)

            Slider(value: $lockDuration, in: 15...480, step: 15)
                .tint(.lockInPrimary)

            HStack {
                Text("15 min")
                Spacer()
                Text("8 hours")
            }
            .font(.system(size: 13))
            .foregroundColor(.lockInTextSecondary)

            LockInButton("Continue", icon: "arrow.right") {
                step = .review
            }

            Spacer()
        }
    }

    // MARK: - Review
    private var reviewView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 56))
                .foregroundColor(.lockInSuccess)

            Text("Ready to Lock")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.lockInText)

            VStack(spacing: 8) {
                InfoRow(label: "Apps", value: "\(shieldManager.selectedApps.applicationTokens.count) selected")
                InfoRow(label: "Duration", value: "\(Int(lockDuration)) minutes")
                InfoRow(label: "PIN Protected", value: "Yes ✓")
            }
            .lockInCard()

            LockInButton("Activate Lock 🔒", icon: "lock.fill") {
                shieldManager.quickLock(minutes: Int(lockDuration))
            }

            Spacer()
        }
    }
}

// MARK: - Info Row
private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.lockInTextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.lockInText)
        }
        .font(.system(size: 15))
    }
}
