import Foundation
import Supabase
import Realtime

/// Handles unlock requests between pact members — request, approve, deny.
@MainActor
final class UnlockRequestService: ObservableObject {
    @Published var pendingRequests: [UnlockRequest] = []   // Requests I need to approve/deny
    @Published var myRequests: [UnlockRequest] = []        // Requests I've sent
    @Published var isLoading = false
    @Published var error: String?

    private var realtimeChannel: RealtimeChannelV2?

    // MARK: - Send Request

    func requestUnlock(
        requesterId: UUID,
        pactId: UUID,
        appIdentifier: String,
        reason: String?
    ) async -> Bool {
        isLoading = true
        error = nil
        defer { isLoading = false }

        // Validate inputs
        let safeAppId = String(appIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).prefix(100))
        let safeReason = reason.map { String($0.trimmingCharacters(in: .whitespacesAndNewlines).prefix(500)) }

        guard !safeAppId.isEmpty else {
            self.error = "App name cannot be empty"
            return false
        }

        let data: [String: String] = [
            "requester_id": requesterId.uuidString,
            "pact_id": pactId.uuidString,
            "app_identifier": safeAppId,
            "reason": safeReason ?? "",
            "status": "pending"
        ]

        do {
            try await supabase
                .from("unlock_requests")
                .insert(data)
                .execute()

            await fetchMyRequests(userId: requesterId)
            return true
        } catch let error as PostgrestError {
            if error.message.contains("Too many pending") || error.message.contains("max 5") {
                self.error = "Too many pending requests. Wait for responses."
            } else {
                self.error = "Failed to send unlock request"
            }
            #if DEBUG
            print("Failed to send unlock request: \(error)")
            #endif
            return false
        } catch {
            self.error = "Failed to send unlock request"
            #if DEBUG
            print("Failed to send unlock request: \(error)")
            #endif
            return false
        }
    }

    // MARK: - Respond to Request

    func approveRequest(_ request: UnlockRequest, responderId: UUID) async {
        await respond(to: request, status: .approved, responderId: responderId)
    }

    func denyRequest(_ request: UnlockRequest, responderId: UUID) async {
        await respond(to: request, status: .denied, responderId: responderId)
    }

    private func respond(to request: UnlockRequest, status: UnlockRequest.Status, responderId: UUID) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        // Client-side self-approval check (server RLS also prevents this)
        guard responderId != request.requesterId else {
            self.error = "You cannot approve your own request"
            return
        }

        // Client-side check: only respond to pending requests
        guard request.status == .pending else {
            self.error = "This request has already been responded to"
            return
        }

        do {
            try await supabase
                .from("unlock_requests")
                .update([
                    "status": status.rawValue,
                    "responder_id": responderId.uuidString,
                    "responded_at": ISO8601DateFormatter().string(from: .now)
                ])
                .eq("id", value: request.id.uuidString)
                .execute()

            await fetchPendingRequests(userId: responderId)
        } catch {
            self.error = "Failed to \(status.rawValue) request"
            #if DEBUG
            print("Failed to respond to request: \(error)")
            #endif
        }
    }

    // MARK: - Fetch

    /// Fetch requests I need to approve/deny (from my pact members).
    func fetchPendingRequests(userId: UUID) async {
        do {
            // Get my pact IDs
            let memberships: [PactMember] = try await supabase
                .from("pact_members")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            let pactIds = memberships.map { $0.pactId.uuidString }
            guard !pactIds.isEmpty else {
                pendingRequests = []
                return
            }

            let requests: [UnlockRequest] = try await supabase
                .from("unlock_requests")
                .select()
                .in("pact_id", values: pactIds)
                .neq("requester_id", value: userId.uuidString) // Not my own requests
                .eq("status", value: "pending")
                .order("created_at", ascending: false)
                .execute()
                .value

            pendingRequests = requests
        } catch {
            #if DEBUG
            print("Failed to fetch pending requests: \(error)")
            #endif
        }
    }

    /// Fetch my own requests and their status.
    func fetchMyRequests(userId: UUID) async {
        do {
            let requests: [UnlockRequest] = try await supabase
                .from("unlock_requests")
                .select()
                .eq("requester_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .limit(20)
                .execute()
                .value

            myRequests = requests
        } catch {
            #if DEBUG
            print("Failed to fetch my requests: \(error)")
            #endif
        }
    }

    // MARK: - Realtime (v2 API)

    func listenForNewRequests(userId: UUID) async {
        // Clean up existing channel
        if let existing = realtimeChannel {
            await supabase.realtimeV2.removeChannel(existing)
        }

        let channel = supabase.realtimeV2.channel("unlock-requests")

        let insertions = channel.postgresChange(InsertAction.self, table: "unlock_requests")

        await channel.subscribe()

        self.realtimeChannel = channel

        Task { [weak self] in
            for await _ in insertions {
                await self?.fetchPendingRequests(userId: userId)
            }
        }
    }

    func stopListening() async {
        if let channel = realtimeChannel {
            await supabase.realtimeV2.removeChannel(channel)
            realtimeChannel = nil
        }
    }

    // MARK: - Cleanup

    /// Clear all cached data (call on sign-out).
    func reset() {
        pendingRequests = []
        myRequests = []
        error = nil
    }
}
