import SwiftUI

/// Card showing an unlock request that needs approval.
struct RequestCard: View {
    let request: UnlockRequest
    let requesterName: String
    let onApprove: () -> Void
    let onDeny: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top) {
                // Avatar
                let initial = String(requesterName.prefix(1)).uppercased()
                Text(initial)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lockInPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.lockInPrimary.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(requesterName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.lockInText)

                    Text("wants to unlock an app")
                        .font(.system(size: 13))
                        .foregroundColor(.lockInTextSecondary)
                }

                Spacer()

                Text(timeAgo(request.createdAt))
                    .font(.system(size: 11))
                    .foregroundColor(.lockInTextTertiary)
            }

            // App identifier
            HStack(spacing: 8) {
                Image(systemName: "app.badge.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(LockInGradient.primary)

                Text(request.appIdentifier)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.lockInText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.lockInSurfaceLight)
            .cornerRadius(10)

            // Reason
            if let reason = request.reason, !reason.isEmpty {
                Text("\"\(reason)\"")
                    .font(.system(size: 13))
                    .italic()
                    .foregroundColor(.lockInTextSecondary)
                    .padding(.horizontal, 4)
            }

            // Action buttons
            HStack(spacing: 10) {
                Button {
                    let g = UIImpactFeedbackGenerator(style: .medium)
                    g.impactOccurred()
                    onDeny()
                } label: {
                    Text("Deny")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color.lockInSurfaceLight)
                        .foregroundColor(.lockInText)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                }
                .accessibilityLabel("Deny unlock request from \(requesterName)")

                Button {
                    let g = UIImpactFeedbackGenerator(style: .medium)
                    g.impactOccurred()
                    onApprove()
                } label: {
                    Text("Approve")
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(LockInGradient.primary)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }
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
