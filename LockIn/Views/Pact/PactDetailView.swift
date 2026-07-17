import SwiftUI

struct PactDetailView: View {
    let pact: Pact
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var pactService: PactService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isCopied = false
    @State private var showLeaveConfirmation = false
    @State private var isLeaving = false

    private var members: [PactMember] {
        pactService.members(for: pact.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LKSpace.xl) {
                // ── Header: name leads, big and left ──
                VStack(alignment: .leading, spacing: LKSpace.xs) {
                    Text("THE PACT")
                        .font(.lkMicro)
                        .tracking(2)
                        .foregroundColor(.lockInTextTertiary)

                    Text(pact.name)
                        .font(.lkDisplay)
                        .tracking(-0.6)
                        .foregroundColor(.lockInText)
                        .minimumScaleFactor(0.7)

                    Text("\(members.count) of 4 holding the key")
                        .font(.lkCallout)
                        .foregroundColor(.lockInTextSecondary)
                }
                .padding(.top, LKSpace.sm)

                // ── Invite code — the hero. Big mono, tappable, lit. ──
                inviteCodeCard

                // ── Members, shown as people ──
                membersSection

                Spacer(minLength: LKSpace.sm)

                // ── Leaving is destructive — it looks it ──
                LockInButton("Leave Pact", icon: "person.badge.minus", style: .danger) {
                    showLeaveConfirmation = true
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .lockInScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
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

    // MARK: - Invite code (hero)
    private var inviteCodeCard: some View {
        Button {
            UIPasteboard.general.string = pact.inviteCode
            let g = UIImpactFeedbackGenerator(style: .light)
            g.impactOccurred()
            if reduceMotion {
                isCopied = true
            } else {
                withAnimation(.lkSnappy) { isCopied = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.lkSmooth) { isCopied = false }
            }
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

                Text(isCopied ? "Copied — now go share it." : "Tap to copy, then send it to your people.")
                    .font(.lkCaption)
                    .foregroundColor(isCopied ? .lockInSuccess : .lockInTextTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(ScaleButtonStyle())
        .lockInCard()
        .accessibilityLabel("Invite code \(pact.inviteCode). \(isCopied ? "Copied." : "Double tap to copy.")")
    }

    // MARK: - Members
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: LKSpace.lg) {
            Text("MEMBERS")
                .font(.lkMicro)
                .tracking(2)
                .foregroundColor(.lockInTextTertiary)

            if members.isEmpty {
                HStack(spacing: LKSpace.md) {
                    ProgressView().tint(.lockInPrimary)
                    Text("Gathering your people…")
                        .font(.lkCallout)
                        .foregroundColor(.lockInTextSecondary)
                }
                .padding(.vertical, LKSpace.sm)
            } else {
                VStack(spacing: LKSpace.lg) {
                    ForEach(members) { member in
                        memberRow(member)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lockInCard()
    }

    private func memberRow(_ member: PactMember) -> some View {
        HStack(spacing: LKSpace.lg) {
            Text(member.profile?.avatarEmoji ?? "🔥")
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(Color.lockInSurfaceHi)
                .clipShape(Circle())
                .lockInHairlineStroke(LKRadius.pill)

            VStack(alignment: .leading, spacing: 2) {
                Text(member.profile?.displayName ?? "Member")
                    .font(.lkBodyStrong)
                    .foregroundColor(.lockInText)

                Text("Joined \(member.joinedAt.formatted(.relative(presentation: .named)))")
                    .font(.lkCaption)
                    .foregroundColor(.lockInTextTertiary)
            }

            Spacer(minLength: LKSpace.sm)

            if member.userId == pact.createdBy {
                Text("Founder")
                    .font(.lkMicro)
                    .foregroundColor(.lockInPrimary)
                    .padding(.horizontal, LKSpace.sm)
                    .padding(.vertical, LKSpace.xs)
                    .background(Color.lockInPrimary.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .accessibilityElement(children: .combine)
    }
}
