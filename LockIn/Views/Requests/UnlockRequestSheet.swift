import SwiftUI

/// Sheet for creating a new unlock request — pick a pact, name the app, give a reason.
struct UnlockRequestSheet: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var pactService: PactService
    @EnvironmentObject var unlockRequestService: UnlockRequestService
    @EnvironmentObject var shieldManager: ShieldManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPact: Pact?
    @State private var appName = ""
    @State private var reason = ""
    @State private var isSending = false
    @State private var didSend = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("🔓")
                            .font(.system(size: 48))

                        Text("Request Unlock")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.lockInText)

                        Text("Ask your pact to unlock an app for you.")
                            .font(.system(size: 15))
                            .foregroundColor(.lockInTextSecondary)
                    }
                    .padding(.top, 12)

                    // Select Pact
                    if pactService.myPacts.count > 1 {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("WHICH PACT?")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.lockInTextSecondary)
                                .tracking(1.5)

                            ForEach(pactService.myPacts) { pact in
                                Button {
                                    selectedPact = pact
                                } label: {
                                    HStack {
                                        Text(pact.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.lockInText)
                                        Spacer()
                                        Image(systemName: selectedPact?.id == pact.id ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedPact?.id == pact.id ? .lockInPrimary : .lockInTextSecondary)
                                    }
                                    .padding(14)
                                    .background(selectedPact?.id == pact.id ? Color.lockInPrimary.opacity(0.1) : Color.lockInSurfaceLight)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .lockInCard()
                    }

                    // App name
                    VStack(alignment: .leading, spacing: 10) {
                        Text("WHICH APP?")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.lockInTextSecondary)
                            .tracking(1.5)

                        TextField("e.g. Instagram, Twitter, TikTok", text: $appName)
                            .font(.system(size: 16))
                            .padding(16)
                            .background(Color.lockInSurfaceLight)
                            .cornerRadius(12)
                            .foregroundColor(.lockInText)
                            .autocorrectionDisabled()
                    }
                    .lockInCard()

                    // Reason (optional)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("WHY?")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.lockInTextSecondary)
                                .tracking(1.5)
                            Spacer()
                            Text("Optional")
                                .font(.system(size: 12))
                                .foregroundColor(.lockInTextTertiary)
                        }

                        TextField("e.g. Need to check a DM real quick", text: $reason)
                            .font(.system(size: 16))
                            .padding(16)
                            .background(Color.lockInSurfaceLight)
                            .cornerRadius(12)
                            .foregroundColor(.lockInText)
                    }
                    .lockInCard()

                    // Success state
                    if didSend {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.lockInSuccess)
                            Text("Request sent! Waiting for approval...")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.lockInSuccess)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(Color.lockInSuccess.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Send button
                    if !didSend {
                        LockInButton("Send Request", icon: "paperplane.fill", disabled: !canSend) {
                            Task { await sendRequest() }
                        }
                        .opacity(canSend ? 1 : 0.5)
                    } else {
                        LockInButton("Done", style: .secondary) {
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .lockInScreenBackground()
            .navigationTitle("New Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.lockInTextSecondary)
                }
            }
            .loadingOverlay(isSending, message: "Sending...")
            .onAppear {
                // Auto-select the first pact if only one
                if pactService.myPacts.count == 1 {
                    selectedPact = pactService.myPacts.first
                }
            }
        }
    }

    private var sanitizedAppName: String {
        String(appName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(100))
    }

    private var sanitizedReason: String {
        String(reason.trimmingCharacters(in: .whitespacesAndNewlines).prefix(500))
    }

    private var canSend: Bool {
        selectedPact != nil && !sanitizedAppName.isEmpty && !isSending
    }

    private func sendRequest() async {
        guard let userId = authService.currentUser?.id,
              let pact = selectedPact else { return }

        isSending = true
        defer { isSending = false }

        let success = await unlockRequestService.requestUnlock(
            requesterId: userId,
            pactId: pact.id,
            appIdentifier: sanitizedAppName,
            reason: sanitizedReason.isEmpty ? nil : sanitizedReason
        )

        if success {
            didSend = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}
