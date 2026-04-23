import SwiftUI
import WidgetKit

struct StreakWidget: Widget {
    let kind = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotTimelineProvider()) { entry in
            StreakView(snapshot: entry.snapshot)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName("Streak")
        .description("Your current perfect-day streak and best streak.")
        .supportedFamilies([.systemSmall])
    }
}

private struct StreakView: View {
    @Environment(\.colorScheme) private var scheme
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(spacing: 4) {
            Text("🔥")
                .font(.system(size: 38))
                .shadow(color: WidgetPalette.warning.opacity(0.5), radius: 8, x: 0, y: 2)
            Text("\(snapshot.currentPerfectStreak)")
                .font(.system(size: 36, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(.primary)
            Text("day streak")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(WidgetPalette.warning)
            Text("Best: \(snapshot.bestPerfectStreak)")
                .font(.system(size: 10))
                .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                .padding(.top, 2)
        }
    }
}
