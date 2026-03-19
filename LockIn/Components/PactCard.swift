import SwiftUI

/// Card showing a pact group with member emoji avatars and status.
struct PactCard: View {
    let pact: Pact
    let members: [PactMember]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pact.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.lockInText)

                    Text("\(members.count)/4 members")
                        .font(.system(size: 13))
                        .foregroundColor(.lockInTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.lockInTextTertiary)
            }

            // Member emoji avatars — overlapping circles
            if !members.isEmpty {
                HStack(spacing: -8) {
                    ForEach(members.prefix(4)) { member in
                        let emoji = member.profile?.avatarEmoji ?? "🔥"
                        Text(emoji)
                            .font(.system(size: 18))
                            .frame(width: 36, height: 36)
                            .background(Color.lockInPrimary.opacity(0.1))
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.lockInSurface, lineWidth: 2.5)
                            )
                    }

                    // Empty slots
                    let emptySlots = max(0, 4 - members.count)
                    if emptySlots > 0 {
                        ForEach(0..<emptySlots, id: \.self) { _ in
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.lockInTextTertiary)
                                .frame(width: 36, height: 36)
                                .background(Color.lockInSurfaceLight)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.lockInSurface, lineWidth: 2.5)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.lockInPrimary.opacity(0.15), lineWidth: 1)
                                )
                        }
                    }
                }
            }

            // Invite code — tap-to-copy style
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.system(size: 10, weight: .medium))
                Text(pact.inviteCode)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(1)
            }
            .foregroundColor(.lockInTextTertiary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.lockInSurfaceLight)
            .cornerRadius(8)
        }
        .lockInCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pact.name), \(members.count) members, code \(pact.inviteCode)")
    }
}
