import SwiftUI

/// Full-screen view shown when a lock session is active.
struct ActiveLockView: View {
    @EnvironmentObject var shieldManager: ShieldManager
    @State private var timeRemaining: TimeInterval = 0
    @State private var totalDuration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showEndConfirmation = false

    let profile: LockProfile

    var body: some View {
        ZStack {
            Color.lockInBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                TimerRing(
                    progress: totalDuration > 0 ? timeRemaining / totalDuration : 0,
                    timeRemaining: formatTime(timeRemaining),
                    isActive: true
                )

                VStack(spacing: 8) {
                    Text(profile.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.lockInText)

                    Text("\(profile.applicationTokens.count) apps locked")
                        .font(.system(size: 15))
                        .foregroundColor(.lockInTextSecondary)
                }

                AppIconGrid(
                    appTokens: profile.applicationTokens,
                    maxDisplay: 8
                )
                .padding(.horizontal, 40)

                Spacer()

                // Motivational message
                Text(motivationalMessage)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.lockInTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Emergency unlock (guardian mode bypasses this)
                if SharedDefaults.shared.getUserMode() == .selfLock {
                    Button("End Session Early") {
                        showEndConfirmation = true
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.lockInDanger.opacity(0.6))
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
        .alert("End Session?", isPresented: $showEndConfirmation) {
            Button("Keep Going", role: .cancel) {}
            Button("End Session", role: .destructive) {
                shieldManager.stopProfile(profile)
            }
        } message: {
            Text("You'll lose your lock streak. Stay focused!")
        }
    }

    // MARK: - Timer

    private func startTimer() {
        totalDuration = Double(profile.durationMinutes * 60)
        timeRemaining = totalDuration

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                shieldManager.stopProfile(profile)
            }
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private var motivationalMessage: String {
        let messages = [
            "Stay focused. You've got this. 💪",
            "Great things never come from comfort zones.",
            "Every minute of focus builds momentum.",
            "Your future self will thank you.",
            "Discipline is choosing what you want most\nover what you want now.",
        ]
        return messages.randomElement() ?? messages[0]
    }
}
