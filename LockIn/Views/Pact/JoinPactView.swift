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

    private var isComplete: Bool { code.count >= 6 }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: LKSpace.xl) {
                Spacer().frame(height: LKSpace.lg)

                VStack(alignment: .leading, spacing: LKSpace.md) {
                    Text("Drop the")
                        .foregroundColor(.lockInText)
                    + Text(" code.")
                        .foregroundColor(.lockInPrimary)
                }
                .font(.system(size: 36, weight: .black))
                .tracking(-1)
                .minimumScaleFactor(0.7)

                Text("Six characters from whoever invited you. Enter them and you’re in their pact.")
                    .font(.lkBody)
                    .foregroundColor(.lockInTextSecondary)
                    .lineSpacing(3)
                    .frame(maxWidth: 320, alignment: .leading)

                // ── Code input — big mono, lights up when complete ──
                TextField("", text: $code, prompt: Text("ABC123").foregroundColor(.lockInTextTertiary))
                    .font(.lkMono(34, .black))
                    .tracking(8)
                    .foregroundColor(.lockInPrimary)
                    .tint(.lockInPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .focused($isFocused)
                    .padding(LKSpace.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.lockInSurface)
                    .clipShape(RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous))
                    .lockInHairlineStroke(LKRadius.md)
                    .lockInGlow(.lockInGlow, radius: isComplete ? 18 : 0, intensity: isComplete ? 0.4 : 0)
                    .animation(.lkSmooth, value: isComplete)
                    .onChange(of: code) { newValue in
                        code = String(newValue.prefix(6)).uppercased()
                    }
                    .padding(.top, LKSpace.sm)

                // Status message
                if let result = joinResult {
                    HStack(spacing: LKSpace.sm) {
                        Image(systemName: result == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        Text(resultMessage(result))
                    }
                    .font(.lkCallout)
                    .foregroundColor(result == .success ? .lockInSuccess : .lockInDanger)
                    .transition(.opacity.combined(with: .scale))
                }

                LockInButton("Join Pact", icon: "person.badge.plus", disabled: !isComplete || pactService.isLoading) {
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

                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
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
