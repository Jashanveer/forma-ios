import SwiftUI
import WidgetKit

struct WeeklyWidget: Widget {
    let kind = "WeeklyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotTimelineProvider()) { entry in
            WeeklyView(snapshot: entry.snapshot)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName("This Week")
        .description("A 7-day bar chart of how consistent you've been.")
        .supportedFamilies([.systemMedium])
    }
}

private struct WeeklyView: View {
    @Environment(\.colorScheme) private var scheme
    let snapshot: WidgetSnapshot

    private var average: Double {
        guard !snapshot.weeklyPcts.isEmpty else { return 0 }
        let sum = snapshot.weeklyPcts.reduce(0) { $0 + $1.pct }
        return sum / Double(snapshot.weeklyPcts.count)
    }

    var body: some View {
        let todayIndex = snapshot.weeklyPcts.count - 1
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("This Week")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(Int((average * 100).rounded()))% avg")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(WidgetPalette.accent)
            }

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(snapshot.weeklyPcts.enumerated()), id: \.offset) { idx, day in
                    let isToday = idx == todayIndex
                    let color = Color.bar(pct: day.pct, scheme: scheme)
                    VStack(spacing: 4) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(WidgetPalette.trackColor(scheme))
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(color)
                                .frame(height: max(4, day.pct * 80))
                        }
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(isToday
                                        ? (scheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.15))
                                        : Color.clear,
                                        lineWidth: 1.5)
                        )

                        Text(day.label)
                            .font(.system(size: 9, weight: isToday ? .bold : .medium))
                            .foregroundStyle(isToday ? Color.primary : WidgetPalette.subtleForeground(scheme))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
