import Foundation

/// Computes streak data from lock_sessions — how many consecutive days the user has been locking in.
@MainActor
final class StreakService: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var totalLockDays: Int = 0
    @Published var totalLocksThisWeek: Int = 0

    struct LockDay: Codable {
        let createdAt: Date

        enum CodingKeys: String, CodingKey {
            case createdAt = "created_at"
        }
    }

    /// Fetch and compute streak from Supabase lock_sessions.
    func computeStreak(userId: UUID) async {
        do {
            // Fetch all lock sessions for this user, ordered by date
            let sessions: [LockDay] = try await supabase
                .from("lock_sessions")
                .select("created_at")
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            guard !sessions.isEmpty else {
                currentStreak = 0
                longestStreak = 0
                totalLockDays = 0
                totalLocksThisWeek = 0
                return
            }

            // Extract unique calendar days
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let uniqueDays = Set(sessions.map { calendar.startOfDay(for: $0.createdAt) })
                .sorted(by: >)  // Most recent first

            totalLockDays = uniqueDays.count

            // Count locks this week
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
            totalLocksThisWeek = sessions.filter { $0.createdAt >= weekAgo }.count

            // Compute current streak (consecutive days ending today or yesterday)
            var streak = 0
            var expectedDate = today

            // Allow streak to include today or start from yesterday
            if !uniqueDays.contains(today), let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
                if uniqueDays.contains(yesterday) {
                    expectedDate = yesterday
                } else {
                    // No activity today or yesterday — streak is 0
                    currentStreak = 0
                    longestStreak = computeLongestStreak(days: uniqueDays, calendar: calendar)
                    return
                }
            }

            for day in uniqueDays {
                if day == expectedDate {
                    streak += 1
                    expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate)!
                } else if day < expectedDate {
                    break
                }
            }

            currentStreak = streak
            longestStreak = max(streak, computeLongestStreak(days: uniqueDays, calendar: calendar))

        } catch {
            print("Failed to compute streak: \(error)")
        }
    }

    /// Compute the longest consecutive streak in history.
    private func computeLongestStreak(days: [Date], calendar: Calendar) -> Int {
        guard !days.isEmpty else { return 0 }

        let sorted = days.sorted()
        var longest = 1
        var current = 1

        for i in 1..<sorted.count {
            let prev = sorted[i - 1]
            let curr = sorted[i]
            let diff = calendar.dateComponents([.day], from: prev, to: curr).day ?? 0

            if diff == 1 {
                current += 1
                longest = max(longest, current)
            } else if diff > 1 {
                current = 1
            }
            // diff == 0 means same day, skip
        }

        return longest
    }
}
