import Foundation

/// Shared serialisable snapshot of habit state that the main app writes to the
/// App Group container so the widget extension can render offline.
///
/// This file is compiled into BOTH the main app target and the widget extension
/// target. Keep it dependency-free (Foundation only) — the widget cannot link
/// SwiftData or the main-app Habit model.
struct WidgetSnapshot: Codable {
    struct HabitEntry: Codable, Identifiable {
        let id: String
        let title: String
        let doneToday: Bool
        let icon: String?
    }

    struct WeekdayPct: Codable {
        let label: String
        let key: String
        let pct: Double
    }

    /// Optional server-sourced data. Nil when the user isn't signed in or
    /// hasn't loaded a dashboard yet. Widgets should degrade gracefully.
    struct BackendData: Codable {
        struct MentorCard: Codable {
            let displayName: String
            let consistencyPercent: Int
            let tip: String
            let missedHabitsToday: Int
            let progressScore: Int
        }

        struct MenteeCard: Codable, Identifiable {
            var id: Int64 { matchId }
            let matchId: Int64
            let userId: Int64
            let displayName: String
            let missedHabitsToday: Int
            let consistencyPercent: Int
            let suggestedAction: String
        }

        struct FriendCard: Codable, Identifiable {
            var id: Int64 { userId }
            let userId: Int64
            let displayName: String
            let progressPercent: Int
            let consistencyPercent: Int
        }

        struct LeaderEntry: Codable, Identifiable {
            var id: String { "\(displayName)-\(score)-\(currentUser)" }
            let displayName: String
            let score: Int
            let currentUser: Bool
        }

        struct Challenge: Codable {
            let title: String
            let completedPerfectDays: Int
            let targetPerfectDays: Int
            let rank: Int
        }

        let xp: Int
        let levelName: String
        let weeklyConsistencyPercent: Int
        let accountabilityScore: Int
        let checksToday: Int
        let dailyCap: Int
        let freezesAvailable: Int

        let challenge: Challenge
        let leaderboard: [LeaderEntry]

        let mentor: MentorCard?
        let mentees: [MenteeCard]
        let activeMenteeCount: Int

        let friends: [FriendCard]
        let friendCount: Int
    }

    let generatedAt: Date
    let todayKey: String
    let habits: [HabitEntry]
    let doneToday: Int
    let totalToday: Int
    let currentPerfectStreak: Int
    let bestPerfectStreak: Int
    let weeklyPcts: [WeekdayPct]
    let perfectDaysCount: Int
    let last28DaysDone: [Bool]
    let backend: BackendData?

    static let appGroupID = "group.jashanveer.habit-tracker-macos"
    static let fileName = "widget-snapshot.json"

    static var containerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        )
    }

    static var fileURL: URL? {
        containerURL?.appendingPathComponent(fileName)
    }

    static func load() -> WidgetSnapshot? {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }

    static func placeholder() -> WidgetSnapshot {
        let labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let pcts: [Double] = [1.0, 0.83, 1.0, 0.67, 0.5, 0.83, 0.33]
        let weekly = zip(labels, pcts).map { WeekdayPct(label: $0.0, key: $0.0, pct: $0.1) }
        let habits = [
            HabitEntry(id: "1", title: "Morning Meditation", doneToday: true, icon: "🧘"),
            HabitEntry(id: "2", title: "Read 30 min", doneToday: true, icon: "📚"),
            HabitEntry(id: "3", title: "Workout", doneToday: false, icon: "🏋️"),
            HabitEntry(id: "4", title: "Cold Shower", doneToday: false, icon: "🚿"),
            HabitEntry(id: "5", title: "Journal", doneToday: true, icon: "📝"),
        ]
        let backend = BackendData(
            xp: 2450,
            levelName: "Growing",
            weeklyConsistencyPercent: 82,
            accountabilityScore: 78,
            checksToday: 3,
            dailyCap: 5,
            freezesAvailable: 2,
            challenge: .init(
                title: "Consistency Week",
                completedPerfectDays: 4,
                targetPerfectDays: 7,
                rank: 3
            ),
            leaderboard: [
                .init(displayName: "Maya", score: 6, currentUser: false),
                .init(displayName: "Sam", score: 5, currentUser: false),
                .init(displayName: "You", score: 4, currentUser: true),
                .init(displayName: "Priya", score: 3, currentUser: false),
                .init(displayName: "Jordan", score: 2, currentUser: false),
            ],
            mentor: .init(
                displayName: "Elena Park",
                consistencyPercent: 94,
                tip: "Keep your morning stack intact — you're two days from a new best.",
                missedHabitsToday: 1,
                progressScore: 72
            ),
            mentees: [
                .init(matchId: 1, userId: 101, displayName: "Aarav M", missedHabitsToday: 0, consistencyPercent: 88, suggestedAction: "Send kudos"),
                .init(matchId: 2, userId: 102, displayName: "Riya S",  missedHabitsToday: 2, consistencyPercent: 54, suggestedAction: "Send nudge"),
            ],
            activeMenteeCount: 2,
            friends: [
                .init(userId: 201, displayName: "Maya", progressPercent: 100, consistencyPercent: 92),
                .init(userId: 202, displayName: "Sam",  progressPercent: 80,  consistencyPercent: 76),
                .init(userId: 203, displayName: "Priya", progressPercent: 60, consistencyPercent: 68),
            ],
            friendCount: 12
        )
        return WidgetSnapshot(
            generatedAt: Date(),
            todayKey: "2026-04-18",
            habits: habits,
            doneToday: 3,
            totalToday: 5,
            currentPerfectStreak: 14,
            bestPerfectStreak: 21,
            weeklyPcts: weekly,
            perfectDaysCount: 4,
            last28DaysDone: Array(repeating: true, count: 20) + Array(repeating: false, count: 8),
            backend: backend
        )
    }
}
