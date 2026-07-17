import SwiftUI

struct CreatePactView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var pactService: PactService
    @Environment(\.dismiss) private var dismiss

    @State private var pactName = ""
    @State private var createdPact: Pact?
    @State private var isCopied = false
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            Group {
                if let pact = createdPact {
                    successView(pact: pact)
                } else {
                    createForm
                }
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lockInScreenBackground()
            .navigationTitle(createdPact == nil ? "New Pact" : "Invite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.lockInTextSecondary)
                }
            }
            .loadingOverlay(pactService.isLoading, message: "Creating...")
            .errorBanner(pactService.error) { pactService.error = nil }
        }
    }

    // MARK: - Create Form
    private var createForm: some View {
        VStack(alignment: .leading, spacing: LKSpace.xl) {
            Spacer().frame(height: LKSpace.lg)

            VStack(alignment: .leading, spacing: LKSpace.md) {
                Text("Name your")
                    .foregroundColor(.lockInText)
                + Text(" pact.")
                    .foregroundColor(.lockInPrimary)
            }
            .font(.system(size: 36, weight: .black))
            .tracking(-1)
            .minimumScaleFactor(0.7)

            Text("Give it a name you and your people will recognize. You can invite up to three others once it exists.")
                .font(.lkBody)
                .foregroundColor(.lockInTextSecondary)
                .lineSpacing(3)
                .frame(maxWidth: 320, alignment: .leading)

            TextField("", text: $pactName, prompt: Text("e.g. Startup Grind").foregroundColor(.lockInTextTertiary))
                .font(.lkTitle)
                .foregroundColor(.lockInText)
                .tint(.lockInPrimary)
                .autocorrectionDisabled()
                .focused($nameFocused)
                .padding(LKSpace.lg)
                .background(Color.lockInSurface)
                .clipShape(RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous))
                .lockInHairlineStroke(LKRadius.md)
                .padding(.top, LKSpace.sm)

            LockInButton("Create Pact", icon: "flame.fill", disabled: pactName.trimmingCharacters(in: .whitespaces).isEmpty || pactService.isLoading) {
                guard let userId = authService.currentUser?.id else { return }
                Task {
                    createdPact = await pactService.createPact(name: pactName.trimmingCharacters(in: .whitespaces), userId: userId)
                }
            }

            Spacer()
        }
        .onAppear { nameFocused = true }
    }

    // MARK: - Success
    private func successView(pact: Pact) -> some View {
        VStack(alignment: .leading, spacing: LKSpace.xl) {
            Spacer().frame(height: LKSpace.lg)

            VStack(alignment: .leading, spacing: LKSpace.xs) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(LockInGradient.ember)
                    .lockInGlow(.lockInGlow, radius: 16, intensity: 0.5)
                    .padding(.bottom, LKSpace.sm)

                Text("The pact is lit.")
                    .font(.lkDisplay)
                    .tracking(-0.6)
                    .foregroundColor(.lockInText)
                    .minimumScaleFactor(0.7)

                Text("Send this code to your accountability partner. They tap Join, and you’re holding each other’s key.")
                    .font(.lkBody)
                    .foregroundColor(.lockInTextSecondary)
                    .lineSpacing(3)
                    .frame(maxWidth: 320, alignment: .leading)
                    .padding(.top, LKSpace.xs)
            }

            // Invite code — the hero moment
            Button {
                UIPasteboard.general.string = pact.inviteCode
                let g = UIImpactFeedbackGenerator(style: .light)
                g.impactOccurred()
                isCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { isCopied = false }
            } label: {
                VStack(alignment: .leading, spacing: LKSpace.md) {
                    HStack {
                        Text("INVITE CODE")
                            .font(.lkMicro)
                            .tracking(2)
                            .foregroundColor(.lockInTextTertiary)
                        Spacer()
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isCopied ? .lockInSuccess : .lockInTextSecondary)
                    }

                    Text(pact.inviteCode)
                        .font(.lkMono(40, .black))
                        .tracking(8)
                        .foregroundStyle(LockInGradient.ember)
                        .lockInGlow(.lockInGlow, radius: 22, intensity: 0.45)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)

                    Text(isCopied ? "Copied." : "Tap to copy")
                        .font(.lkCaption)
                        .foregroundColor(isCopied ? .lockInSuccess : .lockInTextTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(ScaleButtonStyle())
            .lockInCard()
            .accessibilityLabel("Invite code \(pact.inviteCode). Double tap to copy.")

            // Share — ghost styling to sit under the code, not compete with it
            if let url = URL(string: "https://lockin.app/join/\(pact.inviteCode)") {
                ShareLink(item: url, message: Text("Join my LockIn pact! Code: \(pact.inviteCode)")) {
                    HStack(spacing: LKSpace.sm) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Share Invite Link")
                            .font(.lkBodyStrong)
                            .tracking(-0.2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundColor(.lockInPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous)
                            .stroke(Color.lockInPrimary.opacity(0.45), lineWidth: 1.5)
                    )
                }
            }

            Spacer()

            LockInButton("Done") { dismiss() }
        }
    }
}
