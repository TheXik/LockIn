import Foundation

/// Handles unlock requests between pact members — request, approve, deny.
@MainActor
final class UnlockRequestService: ObservableObject {
    @Published var pendingRequests: [UnlockRequest] = []   // Requests I need to approve/deny
    @Published var myRequests: [UnlockRequest] = []        // Requests I've sent

    // MARK: - Send Request

    func requestUnlock(
        requesterId: UUID,
        pactId: UUID,
        lockSessionId: UUID,
        appIdentifier: String,
        reason: String?
    ) async -> Bool {
        let data: [String: String] = [
            "requester_id": requesterId.uuidString,
            "pact_id": pactId.uuidString,
            "lock_session_id": lockSessionId.uuidString,
            "app_identifier": appIdentifier,
            "reason": reason ?? "",
            "status": "pending"
        ]

        do {
            try await supabase
                .from("unlock_requests")
                .insert(data)
                .execute()

            await fetchMyRequests(userId: requesterId)
            return true
        } catch {
            print("Failed to send unlock request: \(error)")
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
            print("Failed to respond to request: \(error)")
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
            print("Failed to fetch pending requests: \(error)")
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
            print("Failed to fetch my requests: \(error)")
        }
    }

    // MARK: - Realtime

    func listenForNewRequests(userId: UUID) async {
        let channel = supabase.channel("unlock-requests")

        let changes = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "unlock_requests"
        )

        await channel.subscribe()

        Task {
            for await _ in changes {
                await fetchPendingRequests(userId: userId)
            }
        }
    }
}
