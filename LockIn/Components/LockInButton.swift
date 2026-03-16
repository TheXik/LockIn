import SwiftUI

struct LockInButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void

    enum ButtonStyle {
        case primary
        case secondary
        case danger
        case ghost
    }

    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
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
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: style == .ghost ? 1.5 : 0)
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
        case .primary: return .white
        case .secondary: return .lockInText
        case .danger: return .white
        case .ghost: return .lockInPrimary
        }
    }

    private var borderColor: Color {
        style == .ghost ? .lockInPrimary.opacity(0.5) : .clear
    }
}

#Preview {
    VStack(spacing: 16) {
        LockInButton("Lock In", icon: "lock.fill") {}
        LockInButton("Settings", icon: "gearshape", style: .secondary) {}
        LockInButton("Unlock", icon: "lock.open.fill", style: .danger) {}
        LockInButton("Cancel", style: .ghost) {}
    }
    .padding()
    .lockInGradientBackground()
}
