import AppIntents
import Foundation
import WidgetKit

/// Tap-to-check intent wired into the Checklist and Command Center widgets.
///
/// The widget extension cannot link SwiftData, so `perform()` just writes an
/// entry to the App Group outbox and flips the cached snapshot optimistically.
/// The main app drains the outbox on its next refresh tick (≤15s) and performs
/// the real toggle + backend sync.
struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Habit"
    static var description = IntentDescription("Mark a habit done or undone for today.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Habit ID") var habitId: String
    @Parameter(title: "Day Key") var dayKey: String

    init() {}
    init(habitId: String, dayKey: String) {
        self.habitId = habitId
        self.dayKey = dayKey
    }

    func perform() async throws -> some IntentResult {
        WidgetToggleOutbox.append(habitId: habitId, dayKey: dayKey)
        WidgetToggleOutbox.applyOptimisticToggle(habitId: habitId, dayKey: dayKey)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// Durable outbox shared via the App Group. Widget writes entries; app drains them.
enum WidgetToggleOutbox {
    struct Entry: Codable {
        let habitId: String
        let dayKey: String
        let createdAt: Date
    }

    static let fileName = "widget-toggles.json"

    static var fileURL: URL? {
        WidgetSnapshot.containerURL?.appendingPathComponent(fileName)
    }

    static func append(habitId: String, dayKey: String) {
        guard let url = fileURL else { return }
        var entries = readAll()
        entries.append(.init(habitId: habitId, dayKey: dayKey, createdAt: Date()))
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(entries) else { return }
        if let dir = WidgetSnapshot.containerURL {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        try? data.write(to: url, options: .atomic)
    }

    static func readAll() -> [Entry] {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Entry].self, from: data)) ?? []
    }

    static func clear() {
        guard let url = fileURL else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// Flip the cached snapshot so the widget reflects the tap immediately,
    /// before the main app has a chance to write a fresh snapshot.
    static func applyOptimisticToggle(habitId: String, dayKey: String) {
        guard var snap = WidgetSnapshot.load() else { return }
        guard let idx = snap.habits.firstIndex(where: { $0.id == habitId }) else { return }
        let old = snap.habits[idx]
        let newEntry = WidgetSnapshot.HabitEntry(
            id: old.id,
            title: old.title,
            doneToday: !old.doneToday,
            icon: old.icon
        )
        var newHabits = snap.habits
        newHabits[idx] = newEntry
        let delta = newEntry.doneToday ? 1 : -1
        snap = WidgetSnapshot(
            generatedAt: Date(),
            todayKey: snap.todayKey,
            habits: newHabits,
            doneToday: max(0, min(snap.totalToday, snap.doneToday + delta)),
            totalToday: snap.totalToday,
            currentPerfectStreak: snap.currentPerfectStreak,
            bestPerfectStreak: snap.bestPerfectStreak,
            weeklyPcts: snap.weeklyPcts,
            perfectDaysCount: snap.perfectDaysCount,
            last28DaysDone: snap.last28DaysDone,
            backend: snap.backend
        )
        guard let url = WidgetSnapshot.fileURL else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snap) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
