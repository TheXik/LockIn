import SwiftUI
import ManagedSettings

/// Displays a grid of blocked app tokens with their shield icons.
struct AppIconGrid: View {
    let appTokens: Set<ApplicationToken>
    let maxDisplay: Int

    init(appTokens: Set<ApplicationToken>, maxDisplay: Int = 12) {
        self.appTokens = appTokens
        self.maxDisplay = maxDisplay
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        let tokens = Array(appTokens.prefix(maxDisplay))
        let overflow = appTokens.count - maxDisplay

        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(tokens.indices, id: \.self) { index in
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.lockInSurfaceLight)
                        .frame(width: 56, height: 56)

                    // The Label for ApplicationToken renders the app icon
                    Label(tokens[index])
                        .labelStyle(.iconOnly)
                        .scaleEffect(1.4)
                }
            }

            if overflow > 0 {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.lockInSurfaceLight)
                        .frame(width: 56, height: 56)

                    Text("+\(overflow)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.lockInTextSecondary)
                }
            }
        }
    }
}
