import SwiftUI

/// Card showing a pact group with member avatars.
struct PactCard: View {
    let pact: Pact
    let members: [PactMember]
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(pact.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.lockInText)

                    Spacer()

                    Text("\(members.count) members")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.lockInTextSecondary)
                }

                // Member emoji avatars
                HStack(spacing: -8) {
                    ForEach(members.prefix(4)) { member in
                        Text(member.profile?.avatarEmoji ?? "👤")
                            .font(.system(size: 22))
                            .frame(width: 36, height: 36)
                            .background(Color.lockInSurfaceLight)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.lockInSurface, lineWidth: 2)
                            )
                    }
                }

                // Invite code
                HStack(spacing: 6) {
                    Image(systemName: "link")
                        .font(.system(size: 11))
                    Text(pact.inviteCode)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                }
                .foregroundColor(.lockInPrimary)
            }
            .lockInCard()
        }
        .buttonStyle(.plain)
    }
}
