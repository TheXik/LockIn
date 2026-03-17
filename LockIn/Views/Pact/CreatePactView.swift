import SwiftUI

struct CreatePactView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var pactService: PactService
    @Environment(\.dismiss) private var dismiss

    @State private var pactName = ""
    @State private var createdPact: Pact?
    @State private var isCopied = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                if let pact = createdPact {
                    // Success — show invite code
                    successView(pact: pact)
                } else {
                    // Create form
                    createForm
                }
            }
            .padding(.horizontal, 24)
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
        }
    }

    // MARK: - Create Form
    private var createForm: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 20)

            Text("🤝")
                .font(.system(size: 56))

            Text("Name your pact")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.lockInText)

            TextField("e.g. Startup Grind", text: $pactName)
                .font(.system(size: 18))
                .padding(16)
                .background(Color.lockInSurface)
                .cornerRadius(14)
                .foregroundColor(.lockInText)
                .autocorrectionDisabled()

            LockInButton("Create Pact", icon: "checkmark") {
                guard let userId = authService.currentUser?.id else { return }
                Task {
                    createdPact = await pactService.createPact(name: pactName, userId: userId)
                }
            }
            .disabled(pactName.isEmpty)
            .opacity(pactName.isEmpty ? 0.5 : 1)

            Spacer()
        }
    }

    // MARK: - Success
    private func successView(pact: Pact) -> some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 20)

            Text("✅")
                .font(.system(size: 56))

            Text("Pact created!")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.lockInText)

            Text("Share this code with your accountability partner:")
                .font(.system(size: 15))
                .foregroundColor(.lockInTextSecondary)
                .multilineTextAlignment(.center)

            // Invite code
            Button {
                UIPasteboard.general.string = pact.inviteCode
                isCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { isCopied = false }
            } label: {
                HStack(spacing: 12) {
                    Text(pact.inviteCode)
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundColor(.lockInPrimary)
                        .tracking(4)

                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        .foregroundColor(isCopied ? .lockInSuccess : .lockInTextSecondary)
                }
                .padding(20)
                .background(Color.lockInSurface)
                .cornerRadius(16)
            }

            Text(isCopied ? "Copied!" : "Tap to copy")
                .font(.system(size: 13))
                .foregroundColor(isCopied ? .lockInSuccess : .lockInTextSecondary)

            // Share button
            if let url = URL(string: "https://lockin.app/join/\(pact.inviteCode)") {
                ShareLink(item: url, message: Text("Join my LockIn pact! Code: \(pact.inviteCode)")) {
                    LockInButton("Share Invite Link", icon: "square.and.arrow.up", style: .ghost) {}
                }
            }

            Spacer()

            LockInButton("Done") { dismiss() }
        }
    }
}
