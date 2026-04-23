import SwiftUI
import WidgetKit

struct CommandCenterWidget: Widget {
    let kind = "CommandCenterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotTimelineProvider()) { entry in
            CommandCenterView(snapshot: entry.snapshot)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName("Command Center")
        .description("Checklist, ring, weekly bars, level, and challenge in one view.")
        .supportedFamilies([.systemExtraLarge])
    }
}

private struct CommandCenterView: View {
    @Environment(\.colorScheme) private var scheme
    let snapshot: WidgetSnapshot

    private var progress: Double {
        snapshot.totalToday > 0 ? Double(snapshot.doneToday) / Double(snapshot.totalToday) : 0
    }

    private var dateLine: String {
        snapshot.generatedAt.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private var timeLine: String {
        snapshot.generatedAt.formatted(.dateTime.hour().minute())
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            leftColumn
                .frame(maxWidth: .infinity, alignment: .topLeading)
            centerColumn
                .frame(width: 220)
            rightColumn
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(18)
    }

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Command Center")
                    .font(.system(size: 13, weight: .bold))
                HStack(spacing: 6) {
                    Text(dateLine)
                    Text("·")
                    Text(timeLine)
                }
                .font(.system(size: 10))
                .foregroundStyle(WidgetPalette.subtleForeground(scheme))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Today")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                VStack(spacing: 4) {
                    ForEach(snapshot.habits.prefix(6)) { habit in
                        CCChecklistRow(habit: habit, todayKey: snapshot.todayKey)
                    }
                    if snapshot.habits.isEmpty {
                        Text("No habits yet.")
                            .font(.system(size: 11))
                            .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                    }
                    if snapshot.habits.count > 6 {
                        Text("+\(snapshot.habits.count - 6) more")
                            .font(.system(size: 9))
                            .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var centerColumn: some View {
        VStack(spacing: 10) {
            ProgressRing(
                progress: progress,
                lineWidth: 12,
                tint: WidgetPalette.success,
                track: WidgetPalette.trackColor(scheme)
            ) {
                VStack(spacing: 0) {
                    Text("\(Int((progress * 100).rounded()))%")
                        .font(.system(size: 28, weight: .heavy))
                    Text("\(snapshot.doneToday)/\(snapshot.totalToday) done")
                        .font(.system(size: 10))
                        .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                }
            }
            .frame(width: 130, height: 130)

            HStack(spacing: 8) {
                BadgeStat(icon: "flame.fill", label: "Streak", value: "\(snapshot.currentPerfectStreak)", tint: WidgetPalette.warning)
                BadgeStat(icon: "trophy.fill", label: "Best", value: "\(snapshot.bestPerfectStreak)", tint: WidgetPalette.gold)
                BadgeStat(icon: "star.fill", label: "Perfect", value: "\(snapshot.perfectDaysCount)", tint: WidgetPalette.violet)
            }

            Text("Weekly")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 5) {
                ForEach(Array(snapshot.weeklyPcts.enumerated()), id: \.offset) { idx, day in
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.bar(pct: day.pct, scheme: scheme))
                            .frame(height: max(6, CGFloat(day.pct) * 36))
                        Text(day.label.prefix(1))
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(idx == snapshot.weeklyPcts.count - 1
                                             ? .primary
                                             : WidgetPalette.subtleForeground(scheme))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 44)

            Spacer(minLength: 0)
        }
    }

    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let backend = snapshot.backend {
                LevelCard(backend: backend)
                ChallengeCard(challenge: backend.challenge, leaderboard: backend.leaderboard)
            } else {
                placeholderCard(
                    icon: "star.circle.fill",
                    title: "Sign in to unlock",
                    body: "Level, XP, and weekly challenge data appear here when you're signed in."
                )
            }

            Text("28-day heatmap")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(WidgetPalette.subtleForeground(scheme))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 14), spacing: 3) {
                ForEach(Array(snapshot.last28DaysDone.enumerated()), id: \.offset) { _, done in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(done ? WidgetPalette.success : WidgetPalette.trackColor(scheme))
                        .frame(height: 9)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func placeholderCard(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(WidgetPalette.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                Text(body)
                    .font(.system(size: 10))
                    .foregroundStyle(WidgetPalette.subtleForeground(scheme))
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(WidgetPalette.accent.opacity(0.08)))
    }
}

private struct CCChecklistRow: View {
    @Environment(\.colorScheme) private var scheme
    let habit: WidgetSnapshot.HabitEntry
    let todayKey: String

    var body: some View {
        Button(intent: ToggleHabitIntent(habitId: habit.id, dayKey: todayKey)) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(habit.doneToday ? WidgetPalette.success : .clear)
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(habit.doneToday
                                ? WidgetPalette.success
                                : (scheme == .dark ? Color.white.opacity(0.22) : Color.black.opacity(0.2)),
                                lineWidth: 1.5)
                    if habit.doneToday {
                        Image(systemName: "checkmark")
                            .font(.system(size: 7, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 14, height: 14)
                Text(habit.title)
                    .font(.system(size: 11, weight: .medium))
                    .strikethrough(habit.doneToday)
                    .opacity(habit.doneToday ? 0.55 : 1)
                    .lineLimit(1)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct BadgeStat: View {
    @Environment(\.colorScheme) private var scheme
    let icon: String
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 13, weight: .bold))
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(WidgetPalette.subtleForeground(scheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(scheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03))
        )
    }
}

private struct LevelCard: View {
    @Environment(\.colorScheme) private var scheme
    let backend: WidgetSnapshot.BackendData

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(WidgetPalette.violet)
                Text(backend.levelName)
                    .font(.system(size: 12, weight: .bold))
                Spacer()
                Text("\(backend.xp) XP")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(WidgetPalette.gold)
            }
            HStack(spacing: 6) {
                Label("\(backend.freezesAvailable)", systemImage: "snowflake")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(WidgetPalette.cyan)
                Label("\(backend.checksToday)/\(backend.dailyCap)", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(WidgetPalette.success)
                Spacer()
                Text("\(backend.weeklyConsistencyPercent)% consistent")
                    .font(.system(size: 9))
                    .foregroundStyle(WidgetPalette.subtleForeground(scheme))
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(WidgetPalette.violet.opacity(0.08)))
    }
}

private struct ChallengeCard: View {
    @Environment(\.colorScheme) private var scheme
    let challenge: WidgetSnapshot.BackendData.Challenge
    let leaderboard: [WidgetSnapshot.BackendData.LeaderEntry]

    private var pct: Double {
        guard challenge.targetPerfectDays > 0 else { return 0 }
        return min(1, Double(challenge.completedPerfectDays) / Double(challenge.targetPerfectDays))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 11))
                        .foregroundStyle(WidgetPalette.warning)
                    Text(challenge.title)
                        .font(.system(size: 11, weight: .bold))
                        .lineLimit(1)
                }
                Spacer()
                Text("Rank #\(challenge.rank)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(WidgetPalette.gold)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(WidgetPalette.trackColor(scheme))
                    Capsule()
                        .fill(WidgetPalette.warning)
                        .frame(width: geo.size.width * pct)
                }
            }
            .frame(height: 6)
            Text("\(challenge.completedPerfectDays) / \(challenge.targetPerfectDays) perfect days")
                .font(.system(size: 9))
                .foregroundStyle(WidgetPalette.subtleForeground(scheme))

            if let top = leaderboard.first(where: { $0.currentUser }) ?? leaderboard.first {
                HStack(spacing: 4) {
                    Text("Top:")
                        .font(.system(size: 9))
                        .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                    Text(top.displayName)
                        .font(.system(size: 9, weight: .bold))
                    Text("· \(top.score) pts")
                        .font(.system(size: 9))
                        .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(WidgetPalette.warning.opacity(0.08)))
    }
}
