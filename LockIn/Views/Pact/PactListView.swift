import SwiftUI

struct PactListView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var pactService: PactService
    @State private var showCreatePact = false
    @State private var showJoinPact = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if pactService.myPacts.isEmpty {
                        emptyState
                    } else {
                        ForEach(pactService.myPacts) { pact in
                            NavigationLink {
                                PactDetailView(pact: pact)
                            } label: {
                                PactCard(pact: pact, members: pactService.currentPactMembers) {}
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .navigationTitle("Pacts")
            .lockInScreenBackground()
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Create Pact", systemImage: "plus") {
                            showCreatePact = true
                        }
                        Button("Join Pact", systemImage: "link") {
                            showJoinPact = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.lockInPrimary)
                    }
                }
            }
            .sheet(isPresented: $showCreatePact) { CreatePactView() }
            .sheet(isPresented: $showJoinPact) { JoinPactView() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)

            Text("🤝")
                .font(.system(size: 64))

            Text("No pacts yet")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.lockInText)

            Text("A pact is your accountability group.\nCreate one and invite your co-founder or friend.")
                .font(.system(size: 15))
                .foregroundColor(.lockInTextSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                LockInButton("Create a Pact", icon: "plus") {
                    showCreatePact = true
                }

                LockInButton("Join with Code", icon: "link", style: .ghost) {
                    showJoinPact = true
                }
            }
        }
        .padding(.horizontal, 20)
    }
}
