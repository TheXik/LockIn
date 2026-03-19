import SwiftUI

struct LockInButton: View {
    let title: String
    let icon: String?
    let style: ButtonVariant
    let isDisabled: Bool
    let action: () -> Void

    enum ButtonVariant {
        case primary    // Gradient bg, black text
        case secondary  // Dark surface bg, white text
        case danger     // Red bg, white text
        case ghost      // Transparent, subtle border
    }

    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonVariant = .primary,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isDisabled = disabled
        self.action = action
    }

    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(backgroundView)
            .foregroundColor(isDisabled ? .lockInTextTertiary : foregroundColor)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: style == .ghost ? 1.5 : 0)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .allowsHitTesting(!isDisabled)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isDisabled ? .isStaticText : .isButton)
    }

    @ViewBuilder
    private var backgroundView: some View {
        if isDisabled {
            Color.lockInSurfaceLight
        } else {
            switch style {
            case .primary:
                LockInGradient.primary
            case .secondary:
                Color.lockInSurfaceLight
            case .danger:
                Color.lockInDanger
            case .ghost:
                Color.clear
            }
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .black
        case .secondary: return .lockInText
        case .danger: return .white
        case .ghost: return .lockInPrimary
        }
    }

    private var borderColor: Color {
        if isDisabled { return .lockInTextTertiary.opacity(0.3) }
        return style == .ghost ? Color.lockInPrimary.opacity(0.4) : .clear
    }
}

/// Press-down scale animation for buttons.
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
