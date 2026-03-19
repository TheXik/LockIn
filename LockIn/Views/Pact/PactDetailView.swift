import SwiftUI

struct PactDetailView: View {
    let pact: Pact
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var pactService: PactService
    @Environment(\.dismiss) private var dismiss
    @State private var isCopied = false
    @State private var showLeaveConfirmation = false
    @State private var isLeaving = false

    private var members: [PactMember] {
        pactService.members(for: pact.id)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.lockInPrimary.opacity(0.08))
                            .frame(width: 64, height: 64)

                        Image(systemName: "person.2.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(LockInGradient.primary)
                    }

                    Text(pact.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.lockInText)

                    Text("\(members.count) member\(members.count == 1 ? "" : "s")")
                        .font(.system(size: 14))
                        .foregroundColor(.lockInTextSecondary)
                }
                .padding(.top, 8)

                // Members
                VStack(alignment: .leading, spacing: 16) {
                    Text("MEMBERS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.lockInTextTertiary)
                        .tracking(1.5)

                    if members.isEmpty {
                        HStack(spacing: 10) {
                            ProgressView()
                                .tint(.lockInPrimary)
                            Text("Loading...")
                                .font(.system(size: 14))
                                .foregroundColor(.lockInTextSecondary)
                        }
                        .padding(.vertical, 8)
                    } else {
                        ForEach(members) { member in
                            HStack(spacing: 14) {
                                // Initial avatar
                                let name = member.profile?.displayName ?? "?"
                                let initial = String(name.prefix(1)).uppercased()

                                Text(initial)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.lockInPrimary)
                                    .frame(width: 40, height: 40)
                                    .background(Color.lockInPrimary.opacity(0.12))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(member.profile?.displayName ?? "Member")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.lockInText)

                                    Text("Joined \(member.joinedAt.formatted(.relative(presentation: .named)))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.lockInTextTertiary)
                                }
                                Spacer()

                                if member.userId == pact.createdBy {
                                    Text("Creator")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.lockInPrimary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.lockInPrimary.opacity(0.1))
                                        .cornerRadius(6)
                                }
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
                .lockInCard()

                // Invite code
                VStack(spacing: 12) {
                    Text("INVITE CODE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.lockInTextTertiary)
                        .tracking(1.5)

                    Button {
                        UIPasteboard.general.string = pact.inviteCode
                        isCopied = true
                        let g = UIImpactFeedbackGenerator(style: .light)
                        g.impactOccurred()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { isCopied = false }
                    } label: {
                        HStack {
                            Text(pact.inviteCode)
                                .font(.system(size: 22, weight: .black, design: .monospaced))
                                .foregroundStyle(LockInGradient.primary)
                                .tracking(4)
                            Spacer()
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 14))
                                .foregroundColor(isCopied ? .lockInSuccess : .lockInTextSecondary)
                        }
                    }

                    Text(isCopied ? "Copied!" : "Tap to copy and share")
                        .font(.system(size: 12))
                        .foregroundColor(isCopied ? .lockInSuccess : .lockInTextTertiary)
                }
                .lockInCard()

                // Leave Pact
                LockInButton("Leave Pact", icon: "person.badge.minus", style: .danger) {
                    showLeaveConfirmation = true
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .lockInScreenBackground()
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await pactService.fetchMembers(pactId: pact.id)
        }
        .refreshable {
            await pactService.fetchMembers(pactId: pact.id)
        }
        .loadingOverlay(isLeaving, message: "Leaving pact...")
        .alert("Leave Pact?", isPresented: $showLeaveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Leave", role: .destructive) {
                Task {
                    guard let userId = authService.currentUser?.id else { return }
                    isLeaving = true
                    let success = await pactService.leavePact(pactId: pact.id, userId: userId)
                    isLeaving = false
                    if success { dismiss() }
                }
            }
        } message: {
            Text("You'll lose access to this pact. Your locked apps will stay locked until you join another pact or remove locks manually.")
        }
    }
}
