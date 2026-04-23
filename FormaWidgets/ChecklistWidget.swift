import SwiftUI
import WidgetKit

struct ChecklistWidget: Widget {
    let kind = "ChecklistWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotTimelineProvider()) { entry in
            ChecklistView(snapshot: entry.snapshot)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName("Today's Habits")
        .description("Tap a row to check it off. Syncs to the app.")
        .supportedFamilies([.systemMedium])
    }
}

private struct ChecklistView: View {
    @Environment(\.colorScheme) private var scheme
    let snapshot: WidgetSnapshot

    var body: some View {
        let total = snapshot.totalToday
        let done = snapshot.doneToday
        let pct = total > 0 ? Double(done) / Double(total) : 0
        let visible = Array(snapshot.habits.prefix(5))

        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)
                    Text("\(done) of \(total) done")
                        .font(.system(size: 10))
                        .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                }
                Spacer()
                ProgressRing(
                    progress: pct,
                    lineWidth: 4,
                    tint: WidgetPalette.success,
                    track: WidgetPalette.trackColor(scheme)
                ) {
                    Text("\(Int(pct * 100))%")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.primary)
                }
                .frame(width: 36, height: 36)
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(visible) { habit in
                    ChecklistRow(habit: habit, todayKey: snapshot.todayKey)
                }
                if visible.isEmpty {
                    Text("No habits yet — add one in the app.")
                        .font(.system(size: 11))
                        .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

private struct ChecklistRow: View {
    @Environment(\.colorScheme) private var scheme
    let habit: WidgetSnapshot.HabitEntry
    let todayKey: String

    var body: some View {
        Button(intent: ToggleHabitIntent(habitId: habit.id, dayKey: todayKey)) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(habit.doneToday ? WidgetPalette.success : Color.clear)
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(habit.doneToday
                                ? WidgetPalette.success
                                : (scheme == .dark ? Color.white.opacity(0.22) : Color.black.opacity(0.2)),
                                lineWidth: 1.5)
                    if habit.doneToday {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 16, height: 16)

                Text(habit.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary)
                    .strikethrough(habit.doneToday)
                    .opacity(habit.doneToday ? 0.55 : 1)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
