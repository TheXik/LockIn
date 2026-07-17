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
            HStack(spacing: LKSpace.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.lkBodyStrong)
                    .tracking(-0.2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundColor(isDisabled ? .lockInTextTertiary : foregroundColor)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LKRadius.md, style: .continuous)
                    .stroke(borderColor, lineWidth: strokeWidth)
            )
            // Warm cast under the lit variants — tactile, not the full flame glow.
            .shadow(color: shadowColor, radius: 14, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
        .allowsHitTesting(!isDisabled)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isDisabled ? .isStaticText : .isButton)
    }

    @ViewBuilder
    private var backgroundView: some View {
        if isDisabled {
            Color.lockInSurface
        } else {
            switch style {
            case .primary:
                LockInGradient.ember
            case .secondary:
                // Top-lit warm surface so it reads as a real object, not a flat chip.
                LinearGradient(
                    colors: [Color.lockInSurfaceHi, Color.lockInSurfaceLight],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .danger:
                Color.lockInDanger
            case .ghost:
                Color.clear
            }
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .lockInBackground   // dark ink on the ember fill
        case .secondary: return .lockInText
        case .danger: return .lockInText
        case .ghost: return .lockInPrimary
        }
    }

    private var borderColor: Color {
        if isDisabled { return .lockInHairline }
        switch style {
        case .secondary: return .lockInHairline
        case .ghost: return .lockInPrimary.opacity(0.45)
        default: return .clear
        }
    }

    private var strokeWidth: CGFloat {
        switch style {
        case .ghost: return 1.5
        case .secondary: return 1
        default: return 0
        }
    }

    private var shadowColor: Color {
        guard !isDisabled else { return .clear }
        switch style {
        case .primary: return .lockInEmber.opacity(0.35)
        case .danger: return .lockInDanger.opacity(0.30)
        default: return .clear
        }
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
