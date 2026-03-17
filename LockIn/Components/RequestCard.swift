import SwiftUI

/// Card showing an unlock request that needs approval.
struct RequestCard: View {
    let request: UnlockRequest
    let requesterName: String
    let onApprove: () -> Void
    let onDeny: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(requesterName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.lockInText)

                    Text("wants to unlock")
                        .font(.system(size: 14))
                        .foregroundColor(.lockInTextSecondary)
                }

                Spacer()

                Text(timeAgo(request.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.lockInTextSecondary)
            }

            // App identifier
            HStack(spacing: 8) {
                Image(systemName: "app.fill")
                    .foregroundColor(.lockInPrimary)
                Text(request.appIdentifier)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.lockInText)
            }
            .padding(10)
            .background(Color.lockInSurfaceLight)
            .cornerRadius(10)

            // Reason
            if let reason = request.reason, !reason.isEmpty {
                Text("\"\(reason)\"")
                    .font(.system(size: 14, design: .serif))
                    .italic()
                    .foregroundColor(.lockInTextSecondary)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: onDeny) {
                    Text("Deny")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.lockInSurfaceLight)
                        .foregroundColor(.lockInDanger)
                        .cornerRadius(12)
                }

                Button(action: onApprove) {
                    Text("Approve")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.lockInPrimary)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
            }
        }
        .lockInCard()
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date.now.timeIntervalSince(date))
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }
}
