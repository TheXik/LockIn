import SwiftUI

struct JoinPactView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var pactService: PactService
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @State private var joinResult: JoinResult?
    @FocusState private var isFocused: Bool

    enum JoinResult {
        case success, full, alreadyMember, notFound
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer().frame(height: 20)

                Text("🔗")
                    .font(.system(size: 56))

                Text("Enter invite code")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.lockInText)

                Text("Get this from your accountability partner")
                    .font(.system(size: 15))
                    .foregroundColor(.lockInTextSecondary)

                // Code input
                TextField("ABC123", text: $code)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding(16)
                    .background(Color.lockInSurface)
                    .cornerRadius(14)
                    .foregroundColor(.lockInPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .focused($isFocused)
                    .onChange(of: code) { newValue in
                        code = String(newValue.prefix(6)).uppercased()
                    }

                // Status message
                if let result = joinResult {
                    HStack(spacing: 8) {
                        Image(systemName: result == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        Text(resultMessage(result))
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(result == .success ? .lockInSuccess : .lockInDanger)
                    .transition(.opacity.combined(with: .scale))
                }

                LockInButton("Join Pact", icon: "person.badge.plus", disabled: code.count < 6 || pactService.isLoading) {
                    guard let userId = authService.currentUser?.id else { return }
                    Task {
                        let result = await pactService.joinPact(code: code, userId: userId)
                        switch result {
                        case .success:
                            joinResult = .success
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
                        case .failure(.full):
                            joinResult = .full
                        case .failure(.alreadyMember):
                            joinResult = .alreadyMember
                        case .failure(.notFound), .failure(.unknown):
                            joinResult = .notFound
                        }
                    }
                }
                .opacity(code.count < 6 ? 0.5 : 1)

                Spacer()
            }
            .padding(.horizontal, 24)
            .lockInScreenBackground()
            .navigationTitle("Join Pact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.lockInTextSecondary)
                }
            }
            .loadingOverlay(pactService.isLoading, message: "Joining...")
            .errorBanner(pactService.error) { pactService.error = nil }
            .onAppear { isFocused = true }
        }
    }

    private func resultMessage(_ result: JoinResult) -> String {
        switch result {
        case .success: return "You're in! Welcome to the pact."
        case .full: return "This pact is full (max 4 members)."
        case .alreadyMember: return "You're already in this pact."
        case .notFound: return "Invalid code. Check and try again."
        }
    }
}
