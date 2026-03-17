import SwiftUI

struct LockInButton: View {
    let title: String
    let icon: String?
    let style: ButtonVariant
    let action: () -> Void

    enum ButtonVariant {
        case primary    // Yellow bg, black text
        case secondary  // Dark surface bg, white text
        case danger     // Red bg, white text
        case ghost      // Transparent, yellow border
    }

    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonVariant = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: style == .ghost ? 2 : 0)
            )
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return .lockInPrimary
        case .secondary: return .lockInSurfaceLight
        case .danger: return .lockInDanger
        case .ghost: return .clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .black  // Black text on yellow
        case .secondary: return .lockInText
        case .danger: return .white
        case .ghost: return .lockInPrimary
        }
    }

    private var borderColor: Color {
        style == .ghost ? .lockInPrimary.opacity(0.6) : .clear
    }
}
