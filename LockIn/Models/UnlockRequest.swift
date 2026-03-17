import Foundation

/// A request from one user to unlock a specific app. Needs approval from a pact member.
struct UnlockRequest: Codable, Identifiable, Hashable {
    let id: UUID
    let requesterId: UUID
    let pactId: UUID
    let lockSessionId: UUID
    var appIdentifier: String       // Which app they want to unlock
    var reason: String?             // "Need to check a message real quick"
    var status: Status
    var responderId: UUID?          // Who approved/denied
    var respondedAt: Date?
    let createdAt: Date

    enum Status: String, Codable {
        case pending
        case approved
        case denied
    }

    enum CodingKeys: String, CodingKey {
        case id
        case requesterId = "requester_id"
        case pactId = "pact_id"
        case lockSessionId = "lock_session_id"
        case appIdentifier = "app_identifier"
        case reason, status
        case responderId = "responder_id"
        case respondedAt = "responded_at"
        case createdAt = "created_at"
    }
}
