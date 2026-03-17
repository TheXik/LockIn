import SwiftUI

struct PactDetailView: View {
    let pact: Pact
    @EnvironmentObject var pactService: PactService
    @State private var isCopied = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text("🤝")
                        .font(.system(size: 48))

                    Text(pact.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.lockInText)
                }
                .padding(.top, 12)

                // Members
                VStack(alignment: .leading, spacing: 14) {
                    Text("MEMBERS")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.lockInTextSecondary)
                        .tracking(1.5)

                    ForEach(pactService.currentPactMembers) { member in
                        HStack(spacing: 14) {
                            Text(member.profile?.avatarEmoji ?? "👤")
                                .font(.system(size: 28))
                                .frame(width: 44, height: 44)
                                .background(Color.lockInSurfaceLight)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.profile?.displayName ?? "Member")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.lockInText)

                                Text("Joined \(member.joinedAt.formatted(.relative(presentation: .named)))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.lockInTextSecondary)
                            }
                            Spacer()

                            if member.userId == pact.createdBy {
                                Text("Creator")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.lockInPrimary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.lockInPrimary.opacity(0.15))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                .lockInCard()

                // Invite code
                VStack(spacing: 12) {
                    Text("INVITE CODE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.lockInTextSecondary)
                        .tracking(1.5)

                    Button {
                        UIPasteboard.general.string = pact.inviteCode
                        isCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { isCopied = false }
                    } label: {
                        HStack {
                            Text(pact.inviteCode)
                                .font(.system(size: 24, weight: .black, design: .monospaced))
                                .foregroundColor(.lockInPrimary)
                                .tracking(4)
                            Spacer()
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                .foregroundColor(isCopied ? .lockInSuccess : .lockInTextSecondary)
                        }
                    }

                    Text(isCopied ? "Copied!" : "Tap to copy and share")
                        .font(.system(size: 13))
                        .foregroundColor(isCopied ? .lockInSuccess : .lockInTextSecondary)
                }
                .lockInCard()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .lockInScreenBackground()
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await pactService.fetchMembers(pactId: pact.id)
        }
    }
}
