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
                VStack(alignment: .leading, spacing: LKSpace.xxl) {
                    // ── Header — editorial, left-aligned, one accent word ──
                    VStack(alignment: .leading, spacing: LKSpace.sm) {
                        (
                            Text("Ask for the ")
                                .foregroundColor(.lockInText)
                            + Text("key")
                                .foregroundColor(.lockInPrimary)
                            + Text(" back.")
                                .foregroundColor(.lockInText)
                        )
                        .font(.system(size: 34, weight: .black))
                        .tracking(-1.1)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.7)

                        Text("Name the app and make your case. Your pact decides.")
                            .font(.lkCallout)
                            .foregroundColor(.lockInTextSecondary)
                            .frame(maxWidth: 300, alignment: .leading)
                    }
                    .padding(.top, LKSpace.xs)

                    // ── Which pact (only when there's a choice) ──
                    if pactService.myPacts.count > 1 {
                        VStack(alignment: .leading, spacing: LKSpace.md) {
                            eyebrow("WHICH PACT")

                            VStack(spacing: LKSpace.sm) {
                                ForEach(pactService.myPacts) { pact in
                                    Button {
                                        selectedPact = pact
                                    } label: {
                                        let isSelected = selectedPact?.id == pact.id
                                        HStack {
                                            Text(pact.name)
                                                .font(.lkBodyStrong)
                                                .foregroundColor(.lockInText)
                                            Spacer()
                                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundStyle(isSelected ? AnyShapeStyle(LockInGradient.ember) : AnyShapeStyle(Color.lockInTextTertiary))
                                        }
                                        .padding(LKSpace.lg)
                                        .background(
                                            RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous)
                                                .fill(isSelected ? Color.lockInPrimary.opacity(0.10) : Color.lockInSurfaceLight)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous)
                                                .stroke(isSelected ? Color.lockInPrimary.opacity(0.45) : Color.lockInHairline, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // ── Which app ──
                    VStack(alignment: .leading, spacing: LKSpace.md) {
                        eyebrow("WHICH APP")
                        TextField("Instagram, Twitter, TikTok…", text: $appName)
                            .font(.lkBody)
                            .foregroundColor(.lockInText)
                            .autocorrectionDisabled()
                            .inputField()
                    }

                    // ── Why (optional) ──
                    VStack(alignment: .leading, spacing: LKSpace.md) {
                        HStack {
                            eyebrow("WHY")
                            Spacer()
                            Text("optional")
                                .font(.lkCaption)
                                .foregroundColor(.lockInTextTertiary)
                        }
                        TextField("Need to check one DM, then I'm out", text: $reason)
                            .font(.lkBody)
                            .foregroundColor(.lockInText)
                            .inputField()
                    }

                    // ── Success state ──
                    if didSend {
                        HStack(spacing: LKSpace.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.lockInSuccess)
                            Text("Sent. The ball's in their court now.")
                                .font(.lkCallout)
                                .foregroundColor(.lockInText)
                            Spacer(minLength: 0)
                        }
                        .padding(LKSpace.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous)
                                .fill(Color.lockInSuccess.opacity(0.10))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous)
                                .stroke(Color.lockInSuccess.opacity(0.30), lineWidth: 1)
                        )
                        .transition(.opacity)
                    }

                    // ── Send / Done ──
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

    // MARK: - Small pieces
    private func eyebrow(_ text: String) -> some View {
        Text(text)
            .font(.lkMicro)
            .tracking(1.8)
            .foregroundColor(.lockInTextTertiary)
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
            withAnimation(.lkSnappy) { didSend = true }
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

// MARK: - Input field styling
private extension View {
    func inputField() -> some View {
        self
            .padding(LKSpace.lg)
            .background(
                RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous)
                    .fill(Color.lockInSurfaceLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous)
                    .stroke(Color.lockInHairline, lineWidth: 1)
            )
    }
}
