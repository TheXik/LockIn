import Foundation

/// A user profile synced with Supabase.
struct Profile: Codable, Identifiable, Hashable {
    let id: UUID
    var displayName: String
    var avatarEmoji: String
    var pushToken: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarEmoji = "avatar_emoji"
        case pushToken = "push_token"
        case createdAt = "created_at"
    }
}
