import SwiftUI
import WidgetKit

struct TodayRingWidget: Widget {
    let kind = "TodayRingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotTimelineProvider()) { entry in
            TodayRingView(snapshot: entry.snapshot)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName("Today's Progress")
        .description("A ring showing how many of today's habits you've completed.")
        .supportedFamilies([.systemSmall])
    }
}

private struct TodayRingView: View {
    @Environment(\.colorScheme) private var scheme
    let snapshot: WidgetSnapshot

    var body: some View {
        let total = snapshot.totalToday
        let done = snapshot.doneToday
        let pct = total > 0 ? Double(done) / Double(total) : 0
        VStack(spacing: 6) {
            ProgressRing(
                progress: pct,
                lineWidth: 9,
                tint: WidgetPalette.success,
                track: WidgetPalette.trackColor(scheme)
            ) {
                VStack(spacing: 0) {
                    Text("\(done)")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.primary)
                    Text("of \(max(total, 1))")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                }
            }
            .frame(width: 100, height: 100)

            VStack(spacing: 1) {
                Text("Today")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(snapshot.generatedAt.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundStyle(WidgetPalette.subtleForeground(scheme))
            }
        }
    }
}
