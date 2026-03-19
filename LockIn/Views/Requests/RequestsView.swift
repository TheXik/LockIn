import SwiftUI

struct RequestsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var unlockRequestService: UnlockRequestService
    @State private var selectedTab = 0
    @State private var showUnlockRequestSheet = false
    @State private var confirmingApproval: UnlockRequest?
    @State private var confirmingDenial: UnlockRequest?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented control
                Picker("", selection: $selectedTab) {
                    Text("Incoming").tag(0)
                    Text("My Requests").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 16) {
                        if selectedTab == 0 {
                            incomingRequests
                        } else {
                            myRequests
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                .refreshable {
                    guard let userId = authService.currentUser?.id else { return }
                    if selectedTab == 0 {
                        await unlockRequestService.fetchPendingRequests(userId: userId)
                    } else {
                        await unlockRequestService.fetchMyRequests(userId: userId)
                    }
                }
            }
            .navigationTitle("Requests")
            .lockInScreenBackground()
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showUnlockRequestSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.lockInPrimary)
                    }
                    .accessibilityLabel("New unlock request")
                }
            }
            .sheet(isPresented: $showUnlockRequestSheet) {
                UnlockRequestSheet()
            }
            .loadingOverlay(unlockRequestService.isLoading)
            .errorBanner(unlockRequestService.error) {
                unlockRequestService.error = nil
            }
            // Confirmation dialogs
            .alert("Approve Unlock?", isPresented: .init(
                get: { confirmingApproval != nil },
                set: { if !$0 { confirmingApproval = nil } }
            )) {
                Button("Cancel", role: .cancel) { confirmingApproval = nil }
                Button("Approve") {
                    guard let request = confirmingApproval,
                          let userId = authService.currentUser?.id else { return }
                    Task { await unlockRequestService.approveRequest(request, responderId: userId) }
                    confirmingApproval = nil
                }
            } message: {
                Text("This will let them use the app. Are you sure?")
            }
            .alert("Deny Unlock?", isPresented: .init(
                get: { confirmingDenial != nil },
                set: { if !$0 { confirmingDenial = nil } }
            )) {
                Button("Cancel", role: .cancel) { confirmingDenial = nil }
                Button("Deny", role: .destructive) {
                    guard let request = confirmingDenial,
                          let userId = authService.currentUser?.id else { return }
                    Task { await unlockRequestService.denyRequest(request, responderId: userId) }
                    confirmingDenial = nil
                }
            } message: {
                Text("Their app will stay locked.")
            }
        }
    }

    // MARK: - Incoming
    private var incomingRequests: some View {
        Group {
            if unlockRequestService.pendingRequests.isEmpty {
                emptyState(
                    emoji: "✅",
                    title: "All clear",
                    subtitle: "No pending unlock requests from your pact."
                )
            } else {
                ForEach(unlockRequestService.pendingRequests) { request in
                    RequestCard(
                        request: request,
                        requesterName: "Pact Member", // TODO: resolve from profile
                        onApprove: {
                            confirmingApproval = request
                        },
                        onDeny: {
                            confirmingDenial = request
                        }
                    )
                }
            }
        }
    }

    // MARK: - My Requests
    private var myRequests: some View {
        Group {
            if unlockRequestService.myRequests.isEmpty {
                emptyState(
                    emoji: "🔒",
                    title: "No requests",
                    subtitle: "When you need to unlock an app, tap + to request."
                )
            } else {
                ForEach(unlockRequestService.myRequests) { request in
                    HStack(spacing: 14) {
                        Image(systemName: "app.fill")
                            .foregroundColor(.lockInPrimary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(request.appIdentifier)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.lockInText)

                            Text(request.reason ?? "No reason given")
                                .font(.system(size: 13))
                                .foregroundColor(.lockInTextSecondary)
                        }

                        Spacer()

                        statusBadge(request.status)
                    }
                    .lockInCard()
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Request for \(request.appIdentifier), status: \(request.status.rawValue)")
                }
            }
        }
    }

    // MARK: - Helpers
    private func emptyState(emoji: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 40)
            Text(emoji).font(.system(size: 48))
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.lockInText)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(.lockInTextSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private func statusBadge(_ status: UnlockRequest.Status) -> some View {
        Text(status.rawValue.capitalized)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(statusColor(status))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor(status).opacity(0.15))
            .cornerRadius(8)
    }

    private func statusColor(_ status: UnlockRequest.Status) -> Color {
        switch status {
        case .pending: return .lockInWarning
        case .approved: return .lockInSuccess
        case .denied: return .lockInDanger
        }
    }
}
