import SwiftUI

/// PIN entry gate for guardian-controlled unlock.
struct GuardianPinView: View {
    let onSuccess: () -> Void

    @State private var enteredPin = ""
    @State private var attempts = 0
    @State private var shake = false
    @State private var isLocked = false
    @State private var lockTimer: Timer?
    @State private var lockCountdown = 0

    private let maxAttempts = 5
    private let lockDurationSeconds = 30

    var body: some View {
        ZStack {
            Color.lockInBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.lockInPrimary)

                VStack(spacing: 8) {
                    Text("Guardian PIN Required")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.lockInText)

                    if isLocked {
                        Text("Too many attempts. Try again in \(lockCountdown)s")
                            .font(.system(size: 14))
                            .foregroundColor(.lockInDanger)
                    } else {
                        Text("Enter PIN to manage locks")
                            .font(.system(size: 15))
                            .foregroundColor(.lockInTextSecondary)
                    }
                }

                // PIN dots
                HStack(spacing: 20) {
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(i < enteredPin.count ? Color.lockInPrimary : Color.lockInSurfaceLight)
                            .frame(width: 20, height: 20)
                    }
                }
                .modifier(ShakeEffect(animatableData: CGFloat(shake ? 1 : 0)))

                // Number pad
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    ForEach(1...9, id: \.self) { num in
                        NumberButton(number: "\(num)", isDisabled: isLocked) {
                            appendDigit("\(num)")
                        }
                    }

                    Color.clear.frame(height: 70) // empty space

                    NumberButton(number: "0", isDisabled: isLocked) {
                        appendDigit("0")
                    }

                    Button {
                        if !enteredPin.isEmpty {
                            enteredPin.removeLast()
                        }
                    } label: {
                        Image(systemName: "delete.backward.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.lockInTextSecondary)
                            .frame(width: 70, height: 70)
                    }
                    .disabled(isLocked)
                }
                .padding(.horizontal, 40)

                Spacer()
            }
        }
    }

    private func appendDigit(_ digit: String) {
        guard !isLocked, enteredPin.count < 4 else { return }
        enteredPin += digit

        if enteredPin.count == 4 {
            validatePin()
        }
    }

    private func validatePin() {
        let storedPin = SharedDefaults.shared.getGuardianPin()

        if enteredPin == storedPin {
            onSuccess()
        } else {
            attempts += 1
            withAnimation(.default) { shake.toggle() }

            if attempts >= maxAttempts {
                lockOut()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                enteredPin = ""
            }
        }
    }

    private func lockOut() {
        isLocked = true
        lockCountdown = lockDurationSeconds

        lockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if lockCountdown > 0 {
                lockCountdown -= 1
            } else {
                lockTimer?.invalidate()
                isLocked = false
                attempts = 0
            }
        }
    }
}

// MARK: - Number Button
private struct NumberButton: View {
    let number: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(isDisabled ? .lockInTextSecondary.opacity(0.3) : .lockInText)
                .frame(width: 70, height: 70)
                .background(Color.lockInSurfaceLight)
                .clipShape(Circle())
        }
        .disabled(isDisabled)
    }
}

// MARK: - Shake Effect
struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(translationX: 10 * sin(animatableData * .pi * 4), y: 0)
        )
    }
}
