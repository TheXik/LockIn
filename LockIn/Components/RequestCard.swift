import SwiftUI

/// Card showing an unlock request that needs approval — the moment a friend
/// decides whether to hand back the key. Deny is meant to look consequential;
/// approve is meant to feel earned and lit.
struct RequestCard: View {
    let request: UnlockRequest
    let requesterName: String
    let onApprove: () -> Void
    let onDeny: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LKSpace.lg) {
            // ── Who's asking, and how fresh the ask is ──
            HStack(alignment: .center, spacing: LKSpace.md) {
                let initial = String(requesterName.prefix(1)).uppercased()
                Text(initial)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(LockInGradient.ember)
                    .frame(width: 38, height: 38)
                    .background(Color.lockInSurfaceHi)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.lockInHairline, lineWidth: 1))

                VStack(alignment: .leading, spacing: 1) {
                    Text(requesterName)
                        .font(.lkBodyStrong)
                        .foregroundColor(.lockInText)
                    Text("is asking you to open the door")
                        .font(.lkCaption)
                        .foregroundColor(.lockInTextSecondary)
                }

                Spacer()

                Text(timeAgo(request.createdAt))
                    .font(.lkMono(11, .medium))
                    .foregroundColor(.lockInTextTertiary)
            }

            // ── The ask itself, as the focal statement — the one lit element ──
            VStack(alignment: .leading, spacing: LKSpace.sm) {
                Text("UNLOCK")
                    .font(.lkMicro)
                    .tracking(1.8)
                    .foregroundColor(.lockInTextTertiary)

                HStack(spacing: LKSpace.sm) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(LockInGradient.ember)
                    Text(request.appIdentifier)
                        .font(.lkTitle)
                        .tracking(-0.4)
                        .foregroundColor(.lockInText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(.vertical, LKSpace.md)
            .padding(.horizontal, LKSpace.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous)
                    .fill(Color.lockInSurfaceHi.opacity(0.55))
            )
            .lockInHairlineStroke(LKRadius.md)
            .lockInGlow(.lockInGlow, radius: 16, intensity: 0.28)

            // ── Their case ──
            if let reason = request.reason, !reason.isEmpty {
                Text("“\(reason)”")
                    .font(.lkCallout)
                    .italic()
                    .foregroundColor(.lockInTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // ── The decision. Two real choices, with weight. ──
            HStack(spacing: LKSpace.md) {
                Button {
                    let g = UIImpactFeedbackGenerator(style: .rigid)
                    g.impactOccurred()
                    onDeny()
                } label: {
                    Text("Deny")
                        .font(.lkBodyStrong)
                        .foregroundColor(.lockInDanger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous)
                                .fill(Color.lockInDanger.opacity(0.10))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous)
                                .stroke(Color.lockInDanger.opacity(0.38), lineWidth: 1)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Deny unlock request from \(requesterName)")

                Button {
                    let g = UIImpactFeedbackGenerator(style: .medium)
                    g.impactOccurred()
                    onApprove()
                } label: {
                    Text("Approve")
                        .font(.lkBodyStrong)
                        .foregroundColor(.lockInBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous)
                                .fill(LockInGradient.ember)
                        )
                        .shadow(color: Color.lockInEmber.opacity(0.35), radius: 14, y: 6)
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Approve unlock request from \(requesterName)")
            }
        }
        .lockInCard()
        .accessibilityElement(children: .contain)
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date.now.timeIntervalSince(date))
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }
}
