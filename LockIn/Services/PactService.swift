import Foundation

/// Manages pacts (accountability groups) — create, join, list members.
@MainActor
final class PactService: ObservableObject {
    @Published var myPacts: [Pact] = []
    @Published var pactMembers: [UUID: [PactMember]] = [:]  // Per-pact member lists
    @Published var isLoading = false
    @Published var error: String?

    /// Get members for a specific pact (convenience accessor).
    func members(for pactId: UUID) -> [PactMember] {
        pactMembers[pactId] ?? []
    }

    // MARK: - Create Pact

    func createPact(name: String, userId: UUID) async -> Pact? {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let code = generateInviteCode()
        let pactData: [String: String] = [
            "name": name,
            "invite_code": code,
            "created_by": userId.uuidString
        ]

        do {
            let pact: Pact = try await supabase
                .from("pacts")
                .insert(pactData)
                .select()
                .single()
                .execute()
                .value

            // Auto-join the creator
            try await supabase
                .from("pact_members")
                .insert([
                    "pact_id": pact.id.uuidString,
                    "user_id": userId.uuidString
                ])
                .execute()

            await fetchMyPacts(userId: userId)
            return pact
        } catch {
            self.error = "Failed to create pact"
            print("Failed to create pact: \(error)")
            return nil
        }
    }

    // MARK: - Join Pact

    enum JoinError: Error {
        case full, alreadyMember, notFound, unknown
    }

    func joinPact(code: String, userId: UUID) async -> Result<Pact, JoinError> {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Find pact by invite code
            let pact: Pact = try await supabase
                .from("pacts")
                .select()
                .eq("invite_code", value: code.uppercased())
                .single()
                .execute()
                .value

            // Check member count (max 4)
            let members: [PactMember] = try await supabase
                .from("pact_members")
                .select()
                .eq("pact_id", value: pact.id.uuidString)
                .execute()
                .value

            guard members.count < 4 else {
                self.error = "This pact is full (max 4 members)"
                return .failure(.full)
            }

            // Check not already a member
            guard !members.contains(where: { $0.userId == userId }) else {
                self.error = "You're already in this pact"
                return .failure(.alreadyMember)
            }

            // Join
            try await supabase
                .from("pact_members")
                .insert([
                    "pact_id": pact.id.uuidString,
                    "user_id": userId.uuidString
                ])
                .execute()

            await fetchMyPacts(userId: userId)
            return .success(pact)
        } catch {
            self.error = "Invalid code. Check and try again."
            print("Failed to join pact: \(error)")
            return .failure(.notFound)
        }
    }

    // MARK: - Leave Pact

    func leavePact(pactId: UUID, userId: UUID) async -> Bool {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await supabase
                .from("pact_members")
                .delete()
                .eq("pact_id", value: pactId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()

            pactMembers.removeValue(forKey: pactId)
            await fetchMyPacts(userId: userId)
            return true
        } catch {
            self.error = "Failed to leave pact"
            print("Failed to leave pact: \(error)")
            return false
        }
    }

    // MARK: - Fetch

    func fetchMyPacts(userId: UUID) async {
        do {
            let memberships: [PactMember] = try await supabase
                .from("pact_members")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            let pactIds = memberships.map { $0.pactId.uuidString }
            guard !pactIds.isEmpty else {
                myPacts = []
                return
            }

            let pacts: [Pact] = try await supabase
                .from("pacts")
                .select()
                .in("id", values: pactIds)
                .execute()
                .value

            myPacts = pacts

            // Fetch members for each pact in parallel
            await withTaskGroup(of: (UUID, [PactMember]).self) { group in
                for pact in pacts {
                    group.addTask { [self] in
                        let members = await self.fetchMembersInternal(pactId: pact.id)
                        return (pact.id, members)
                    }
                }
                for await (pactId, members) in group {
                    pactMembers[pactId] = members
                }
            }
        } catch {
            print("Failed to fetch pacts: \(error)")
        }
    }

    func fetchMembers(pactId: UUID) async {
        let members = await fetchMembersInternal(pactId: pactId)
        pactMembers[pactId] = members
    }

    private func fetchMembersInternal(pactId: UUID) async -> [PactMember] {
        do {
            let members: [PactMember] = try await supabase
                .from("pact_members")
                .select("*, profile:profiles(*)")
                .eq("pact_id", value: pactId.uuidString)
                .execute()
                .value
            return members
        } catch {
            print("Failed to fetch members: \(error)")
            return []
        }
    }

    // MARK: - Helpers

    private func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // No ambiguous chars
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}
