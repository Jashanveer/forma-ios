import SwiftUI
import WidgetKit

struct DashboardWidget: Widget {
    let kind = "DashboardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotTimelineProvider()) { entry in
            DashboardView(snapshot: entry.snapshot)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName("Dashboard")
        .description("Ring, streak, perfect days, habit list, and weekly dots in one widget.")
        .supportedFamilies([.systemLarge])
    }
}

private struct DashboardView: View {
    @Environment(\.colorScheme) private var scheme
    let snapshot: WidgetSnapshot

    private var dateLabel: String {
        snapshot.generatedAt.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private var progress: Double {
        snapshot.totalToday > 0 ? Double(snapshot.doneToday) / Double(snapshot.totalToday) : 0
    }

    private var consistencyLabel: String {
        let pct = snapshot.weeklyPcts.isEmpty
            ? 0
            : snapshot.weeklyPcts.reduce(0) { $0 + $1.pct } / Double(snapshot.weeklyPcts.count)
        switch pct {
        case 0.82...: return "Consistent"
        case 0.6...:  return "Rising"
        case 0.3...:  return "Building"
        default:      return "Starting"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Forma")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(dateLabel)
                        .font(.system(size: 11))
                        .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                }
                Spacer()
                Text(consistencyLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WidgetPalette.success)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(WidgetPalette.success.opacity(0.1))
                    )
                    .overlay(
                        Capsule().stroke(WidgetPalette.success.opacity(0.35), lineWidth: 1)
                    )
            }

            HStack(alignment: .center, spacing: 16) {
                ProgressRing(
                    progress: progress,
                    lineWidth: 11,
                    tint: WidgetPalette.success,
                    track: WidgetPalette.trackColor(scheme)
                ) {
                    VStack(spacing: 0) {
                        Text("\(Int((progress * 100).rounded()))%")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundStyle(.primary)
                        Text("today")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                    }
                }
                .frame(width: 120, height: 120)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    StatCard(icon: "checkmark.circle.fill", label: "Done", value: "\(snapshot.doneToday)", tint: WidgetPalette.success)
                    StatCard(icon: "flame.fill",            label: "Streak", value: "\(snapshot.currentPerfectStreak)", tint: WidgetPalette.warning)
                    StatCard(icon: "trophy.fill",           label: "Best",   value: "\(snapshot.bestPerfectStreak)", tint: WidgetPalette.gold)
                    StatCard(icon: "star.fill",             label: "Perfect",value: "\(snapshot.perfectDaysCount)", tint: WidgetPalette.violet)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                ForEach(snapshot.habits.prefix(3)) { h in
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(h.doneToday ? WidgetPalette.success : Color.clear)
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(h.doneToday
                                        ? WidgetPalette.success
                                        : (scheme == .dark ? Color.white.opacity(0.22) : Color.black.opacity(0.2)),
                                        lineWidth: 1.5)
                            if h.doneToday {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 7, weight: .heavy))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: 14, height: 14)

                        Text(h.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(h.doneToday ? WidgetPalette.subtleForeground(scheme) : .primary)
                            .strikethrough(h.doneToday)
                            .lineLimit(1)
                    }
                }
                if snapshot.habits.count > 3 {
                    Text("+\(snapshot.habits.count - 3) more")
                        .font(.system(size: 10))
                        .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                        .padding(.top, 2)
                }
            }

            HStack(spacing: 5) {
                ForEach(Array(snapshot.weeklyPcts.enumerated()), id: \.offset) { idx, day in
                    let color = Color.bar(pct: day.pct, scheme: scheme)
                    let isToday = idx == snapshot.weeklyPcts.count - 1
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(height: 5)
                        .shadow(color: isToday ? color.opacity(0.6) : .clear, radius: 3)
                }
            }
        }
        .padding(20)
    }
}

private struct StatCard: View {
    @Environment(\.colorScheme) private var scheme
    let icon: String
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(WidgetPalette.subtleForeground(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(scheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.07), lineWidth: 0.5)
        )
    }
}
