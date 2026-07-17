import SwiftUI

/// Card showing a pact group — name, the people in it, and its invite code.
struct PactCard: View {
    let pact: Pact
    let members: [PactMember]

    private var openSlots: Int { max(0, 4 - members.count) }

    var body: some View {
        VStack(alignment: .leading, spacing: LKSpace.lg) {
            // ── Name leads, big and left. Chevron sits quietly. ──
            HStack(alignment: .firstTextBaseline) {
                Text(pact.name)
                    .font(.lkHeadline)
                    .tracking(-0.3)
                    .foregroundColor(.lockInText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: LKSpace.md)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.lockInTextTertiary)
            }

            // ── The people. Overlapping avatars, open seats shown as embers-to-be. ──
            HStack(spacing: -10) {
                ForEach(members.prefix(4)) { member in
                    Text(member.profile?.avatarEmoji ?? "🔥")
                        .font(.system(size: 18))
                        .frame(width: 38, height: 38)
                        .background(Color.lockInSurfaceHi)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.lockInSurface, lineWidth: 2.5))
                }

                ForEach(0..<openSlots, id: \.self) { _ in
                    Circle()
                        .fill(Color.lockInSurfaceLight)
                        .frame(width: 38, height: 38)
                        .overlay(
                            Circle().strokeBorder(
                                Color.lockInHairline,
                                style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])
                            )
                        )
                        .overlay(Circle().stroke(Color.lockInSurface, lineWidth: 2.5))
                }

                Spacer(minLength: LKSpace.md)

                Text("\(members.count)/4")
                    .font(.lkMono(13, .bold))
                    .foregroundColor(.lockInTextSecondary)
            }

            // ── Invite code, a warm mono line ──
            HStack(spacing: LKSpace.sm) {
                Image(systemName: "link")
                    .font(.system(size: 10, weight: .bold))
                Text(pact.inviteCode)
                    .font(.lkMono(13, .bold))
                    .tracking(2)
            }
            .foregroundColor(.lockInTextTertiary)
        }
        .lockInCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pact.name), \(members.count) of 4 members, invite code \(pact.inviteCode)")
    }
}
