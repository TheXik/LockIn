import SwiftUI

extension View {
    func lockInCard() -> some View {
        self
            .padding(20)
            .background(Color.lockInSurface)
            .cornerRadius(20)
    }

    func lockInScreenBackground() -> some View {
        self.background(Color.lockInBackground.ignoresSafeArea())
    }
}
