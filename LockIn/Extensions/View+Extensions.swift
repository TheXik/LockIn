import SwiftUI

extension View {
    func lockInCard() -> some View {
        self
            .padding(20)
            .background(Color.lockInSurface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }

    func lockInScreenBackground() -> some View {
        self.background(Color.lockInBackground.ignoresSafeArea())
    }

    /// Shows a semi-transparent loading overlay when isLoading is true.
    func loadingOverlay(_ isLoading: Bool, message: String = "Loading...") -> some View {
        self.overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .lockInPrimary))
                            .scaleEffect(1.3)

                        Text(message)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.lockInTextSecondary)
                    }
                    .padding(28)
                    .background(.ultraThinMaterial.opacity(0.8))
                    .background(Color.lockInSurface.opacity(0.5))
                    .cornerRadius(20)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }

    /// Shows an error banner at the top of the view.
    func errorBanner(_ message: String?, onDismiss: @escaping () -> Void) -> some View {
        self.overlay(alignment: .top) {
            if let message {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.lockInDanger)
                        .font(.system(size: 15))
                    Text(message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.lockInText)
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.lockInTextSecondary)
                    }
                }
                .padding(14)
                .background(Color.lockInDanger.opacity(0.15))
                .background(Color.lockInSurface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.lockInDanger.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4), value: message)
    }
}

/// Brand gradient for accent elements.
struct LockInGradient {
    static let primary = LinearGradient(
        colors: [Color.lockInPrimary, Color.lockInSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let subtle = LinearGradient(
        colors: [Color.lockInPrimary.opacity(0.15), Color.lockInSecondary.opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
