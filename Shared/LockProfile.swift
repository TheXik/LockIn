import Foundation
import ManagedSettings

/// Represents a saved lock configuration — which apps are blocked and for how long.
struct LockProfile: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let applicationTokens: Set<ApplicationToken>
    let categoryTokens: Set<ActivityCategoryToken>
    let durationMinutes: Int
    let createdAt: Date
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String,
        applicationTokens: Set<ApplicationToken>,
        categoryTokens: Set<ActivityCategoryToken>,
        durationMinutes: Int,
        createdAt: Date = .now,
        isActive: Bool = false
    ) {
        self.id = id
        self.name = name
        self.applicationTokens = applicationTokens
        self.categoryTokens = categoryTokens
        self.durationMinutes = durationMinutes
        self.createdAt = createdAt
        self.isActive = isActive
    }
}
