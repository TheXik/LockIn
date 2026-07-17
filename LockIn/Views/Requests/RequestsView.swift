import SwiftUI

struct RequestsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var unlockRequestService: UnlockRequestService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedTab = 0
    @State private var showUnlockRequestSheet = false
    @State private var confirmingApproval: UnlockRequest?
    @State private var confirmingDenial: UnlockRequest?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LKSpace.xl) {
                    header
                    tabSwitcher

                    if selectedTab == 0 {
                        incomingRequests
                    } else {
                        myRequests
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, LKSpace.sm)
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
            .navigationBarTitleDisplayMode(.inline)
            .lockInScreenBackground()
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showUnlockRequestSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(LockInGradient.ember)
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
                Text("You're handing back the key. They get their app.")
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
                Text("The app stays locked. That's the whole point.")
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: LKSpace.xs) {
            Text("Requests")
                .font(.system(size: 40, weight: .black))
                .tracking(-1.2)
                .foregroundColor(.lockInText)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text("This is where the key changes hands.")
                .font(.lkCallout)
                .foregroundColor(.lockInTextSecondary)
        }
    }

    // MARK: - Tab switcher
    private var tabSwitcher: some View {
        HStack(spacing: LKSpace.xl) {
            tabButton("Incoming", index: 0, count: unlockRequestService.pendingRequests.count)
            tabButton("Sent", index: 1, count: 0)
            Spacer()
        }
    }

    private func tabButton(_ title: String, index: Int, count: Int) -> some View {
        Button {
            if reduceMotion {
                selectedTab = index
            } else {
                withAnimation(.lkSnappy) { selectedTab = index }
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.lkHeadline)
                        .foregroundColor(selectedTab == index ? .lockInText : .lockInTextTertiary)
                    if count > 0 {
                        Text("\(count)")
                            .font(.lkMono(12, .bold))
                            .foregroundColor(.lockInBackground)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(LockInGradient.ember))
                    }
                }
                Capsule()
                    .fill(LockInGradient.ember)
                    .frame(height: 2)
                    .opacity(selectedTab == index ? 1 : 0)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Incoming
    private var incomingRequests: some View {
        Group {
            if unlockRequestService.pendingRequests.isEmpty {
                emptyState(
                    title: "Nobody's knocking.",
                    subtitle: "When someone in your pact needs an app unlocked, the call lands here — and it's yours to make."
                )
            } else {
                VStack(spacing: LKSpace.lg) {
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
    }

    // MARK: - My Requests
    private var myRequests: some View {
        Group {
            if unlockRequestService.myRequests.isEmpty {
                emptyState(
                    title: "You haven't asked.",
                    subtitle: "Locked out of something you actually need? Tap + and make your case to the pact."
                )
            } else {
                VStack(spacing: LKSpace.md) {
                    ForEach(unlockRequestService.myRequests) { request in
                        HStack(alignment: .top, spacing: LKSpace.md) {
                            VStack(alignment: .leading, spacing: LKSpace.xs) {
                                Text(request.appIdentifier)
                                    .font(.lkBodyStrong)
                                    .foregroundColor(.lockInText)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)

                                Text(request.reason ?? "No reason given")
                                    .font(.lkCaption)
                                    .foregroundColor(.lockInTextSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: LKSpace.sm)

                            statusBadge(request.status)
                        }
                        .lockInCard()
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Request for \(request.appIdentifier), status: \(request.status.rawValue)")
                    }
                }
            }
        }
    }

    // MARK: - Helpers
    private func emptyState(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: LKSpace.sm) {
            Text(title)
                .font(.system(size: 26, weight: .bold))
                .tracking(-0.6)
                .foregroundColor(.lockInText)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.lkCallout)
                .foregroundColor(.lockInTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 300, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, LKSpace.xxl)
    }

    private func statusBadge(_ status: UnlockRequest.Status) -> some View {
        Text(status.rawValue.uppercased())
            .font(.lkMicro)
            .tracking(0.8)
            .foregroundColor(statusColor(status))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(statusColor(status).opacity(0.14)))
            .overlay(Capsule().stroke(statusColor(status).opacity(0.30), lineWidth: 1))
    }

    private func statusColor(_ status: UnlockRequest.Status) -> Color {
        switch status {
        case .pending: return .lockInWarning
        case .approved: return .lockInSuccess
        case .denied: return .lockInDanger
        }
    }
}
