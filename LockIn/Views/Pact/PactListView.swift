import SwiftUI

struct PactListView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var pactService: PactService
    @State private var showCreatePact = false
    @State private var showJoinPact = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LKSpace.lg) {
                    // ── Editorial header — big, left, type-led ──
                    VStack(alignment: .leading, spacing: LKSpace.xs) {
                        Text("Your")
                            .foregroundColor(.lockInText)
                        + Text(" people.")
                            .foregroundColor(.lockInPrimary)
                    }
                    .font(.system(size: 40, weight: .black))
                    .tracking(-1.2)
                    .minimumScaleFactor(0.7)
                    .padding(.top, LKSpace.sm)
                    .padding(.bottom, LKSpace.xs)

                    if pactService.myPacts.isEmpty {
                        emptyState
                    } else {
                        Text("\(pactService.myPacts.count) PACT\(pactService.myPacts.count == 1 ? "" : "S")")
                            .font(.lkMicro)
                            .tracking(1.5)
                            .foregroundColor(.lockInTextTertiary)

                        ForEach(pactService.myPacts) { pact in
                            NavigationLink {
                                PactDetailView(pact: pact)
                            } label: {
                                PactCard(pact: pact, members: pactService.members(for: pact.id))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .refreshable {
                guard let userId = authService.currentUser?.id else { return }
                await pactService.fetchMyPacts(userId: userId)
            }
            .navigationBarTitleDisplayMode(.inline)
            .lockInScreenBackground()
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { showCreatePact = true } label: {
                            Label("Create Pact", systemImage: "plus")
                        }
                        Button { showJoinPact = true } label: {
                            Label("Join Pact", systemImage: "link")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(LockInGradient.ember)
                            .accessibilityLabel("Create or join a pact")
                    }
                }
            }
            .sheet(isPresented: $showCreatePact) { CreatePactView() }
            .sheet(isPresented: $showJoinPact) { JoinPactView() }
            .loadingOverlay(pactService.isLoading)
            .errorBanner(pactService.error) { pactService.error = nil }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: LKSpace.xl) {
            Spacer().frame(height: LKSpace.lg)

            // A lit flame — the one glowing thing on this screen.
            Image(systemName: "flame.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(LockInGradient.ember)
                .lockInGlow(.lockInGlow, radius: 18, intensity: 0.5)

            VStack(alignment: .leading, spacing: LKSpace.md) {
                Text("You can't lock in alone.")
                    .font(.lkTitle)
                    .tracking(-0.4)
                    .foregroundColor(.lockInText)

                Text("A pact is two to four people who’ll actually tell you no. Start one and pull your co-founder in — or drop the code they sent you.")
                    .font(.lkBody)
                    .foregroundColor(.lockInTextSecondary)
                    .lineSpacing(3)
                    .frame(maxWidth: 320, alignment: .leading)
            }

            VStack(spacing: LKSpace.md) {
                LockInButton("Start a Pact", icon: "plus") {
                    showCreatePact = true
                }
                LockInButton("Join with a Code", icon: "link", style: .ghost) {
                    showJoinPact = true
                }
            }
            .padding(.top, LKSpace.sm)
        }
    }
}
