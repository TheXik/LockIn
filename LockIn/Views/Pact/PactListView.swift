import SwiftUI

struct PactListView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var pactService: PactService
    @State private var showCreatePact = false
    @State private var showJoinPact = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if pactService.myPacts.isEmpty {
                        emptyState
                    } else {
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
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .refreshable {
                guard let userId = authService.currentUser?.id else { return }
                await pactService.fetchMyPacts(userId: userId)
            }
            .navigationTitle("Pacts")
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
                            .font(.system(size: 20))
                            .foregroundStyle(LockInGradient.primary)
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
        VStack(spacing: 28) {
            Spacer().frame(height: 48)

            ZStack {
                Circle()
                    .fill(Color.lockInPrimary.opacity(0.08))
                    .frame(width: 80, height: 80)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(LockInGradient.primary)
            }

            VStack(spacing: 8) {
                Text("No pacts yet")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.lockInText)

                Text("A pact is your accountability group.\nCreate one and invite your co-founder or friend.")
                    .font(.system(size: 15))
                    .foregroundColor(.lockInTextSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                LockInButton("Create a Pact", icon: "plus") {
                    showCreatePact = true
                }

                LockInButton("Join with Code", icon: "link", style: .ghost) {
                    showJoinPact = true
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
