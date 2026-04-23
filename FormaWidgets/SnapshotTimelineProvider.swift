import WidgetKit

/// Single entry type used by every widget — just the app snapshot plus the entry date.
struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

/// Reads the App Group snapshot file and produces a rolling timeline.
/// The widget extension cannot access SwiftData, so the main app is responsible
/// for refreshing the snapshot. This provider simply re-reads it on every
/// timeline refresh (every 15 min by default, or sooner when the app calls
/// `WidgetCenter.reloadAllTimelines()`).
struct SnapshotTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: Date(), snapshot: .placeholder())
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        let snap = WidgetSnapshot.load() ?? .placeholder()
        completion(SnapshotEntry(date: Date(), snapshot: snap))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let snap = WidgetSnapshot.load() ?? .placeholder()
        let now = Date()
        let next = now.addingTimeInterval(60 * 15)
        completion(Timeline(entries: [SnapshotEntry(date: now, snapshot: snap)], policy: .after(next)))
    }
}
