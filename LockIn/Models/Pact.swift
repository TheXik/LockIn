import Foundation

/// An accountability group (2-4 people). Everyone in a pact holds each other accountable.
struct Pact: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    let inviteCode: String
    let createdBy: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name
        case inviteCode = "invite_code"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

/// A member of a pact.
struct PactMember: Codable, Identifiable, Hashable {
    let id: UUID
    let pactId: UUID
    let userId: UUID
    let joinedAt: Date
    var profile: Profile?

    enum CodingKeys: String, CodingKey {
        case id
        case pactId = "pact_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
        case profile
    }
}
