import Foundation

/// A lock configuration set by the user — which apps are locked and when.
struct LockSession: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    let pactId: UUID
    var appIdentifiers: [String]   // Bundle IDs of locked apps
    var scheduleStart: String?     // "09:00" — nil means always active
    var scheduleEnd: String?       // "17:00"
    var scheduleDays: [Int]?       // [1,2,3,4,5] = Mon-Fri
    var dailyLimitMinutes: Int?    // e.g. 30 minutes per day
    var isActive: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case pactId = "pact_id"
        case appIdentifiers = "app_identifiers"
        case scheduleStart = "schedule_start"
        case scheduleEnd = "schedule_end"
        case scheduleDays = "schedule_days"
        case dailyLimitMinutes = "daily_limit_minutes"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}
