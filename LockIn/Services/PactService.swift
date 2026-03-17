import Foundation

/// Manages pacts (accountability groups) — create, join, list members.
@MainActor
final class PactService: ObservableObject {
    @Published var myPacts: [Pact] = []
    @Published var currentPactMembers: [PactMember] = []
    @Published var isLoading = false

    // MARK: - Create Pact

    func createPact(name: String, userId: UUID) async -> Pact? {
        isLoading = true
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
            print("Failed to create pact: \(error)")
            return nil
        }
    }

    // MARK: - Join Pact

    func joinPact(code: String, userId: UUID) async -> Bool {
        isLoading = true
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
                print("Pact is full")
                return false
            }

            // Check not already a member
            guard !members.contains(where: { $0.userId == userId }) else {
                print("Already a member")
                return false
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
            return true
        } catch {
            print("Failed to join pact: \(error)")
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
        } catch {
            print("Failed to fetch pacts: \(error)")
        }
    }

    func fetchMembers(pactId: UUID) async {
        do {
            let members: [PactMember] = try await supabase
                .from("pact_members")
                .select("*, profile:profiles(*)")
                .eq("pact_id", value: pactId.uuidString)
                .execute()
                .value

            currentPactMembers = members
        } catch {
            print("Failed to fetch members: \(error)")
        }
    }

    // MARK: - Helpers

    private func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // No ambiguous chars
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}
