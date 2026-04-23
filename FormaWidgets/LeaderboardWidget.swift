import SwiftUI
import WidgetKit

struct LeaderboardWidget: Widget {
    let kind = "LeaderboardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotTimelineProvider()) { entry in
            LeaderboardView(snapshot: entry.snapshot)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName("Weekly Leaderboard")
        .description("Your rank and the top contenders for the weekly challenge.")
        .supportedFamilies([.systemLarge])
    }
}

private struct LeaderboardView: View {
    @Environment(\.colorScheme) private var scheme
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Challenge")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                    if let c = snapshot.backend?.challenge {
                        Text(c.title)
                            .font(.system(size: 10))
                            .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                            .lineLimit(1)
                    }
                }
                Spacer()
                if let rank = snapshot.backend?.challenge.rank {
                    RankPill(rank: rank)
                }
            }

            if let backend = snapshot.backend {
                Podium(entries: Array(backend.leaderboard.prefix(3)))
                    .frame(height: 90)

                VStack(spacing: 5) {
                    ForEach(Array(backend.leaderboard.dropFirst(3).prefix(5).enumerated()), id: \.offset) { offset, entry in
                        LeaderRow(rank: offset + 4, entry: entry)
                    }
                }
            } else {
                Spacer()
                Text("Sign in to join the weekly challenge")
                    .font(.system(size: 12))
                    .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            }

            Spacer(minLength: 0)
        }
        .padding(20)
    }
}

private struct RankPill: View {
    @Environment(\.colorScheme) private var scheme
    let rank: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "number")
                .font(.system(size: 9, weight: .bold))
            Text("Rank \(rank)")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(WidgetPalette.gold)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(WidgetPalette.gold.opacity(0.14)))
        .overlay(Capsule().stroke(WidgetPalette.gold.opacity(0.4), lineWidth: 0.6))
    }
}

private struct Podium: View {
    @Environment(\.colorScheme) private var scheme
    let entries: [WidgetSnapshot.BackendData.LeaderEntry]

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if entries.count >= 2 { PodiumColumn(entry: entries[1], height: 52, color: WidgetPalette.accent, rank: 2) }
            if entries.count >= 1 { PodiumColumn(entry: entries[0], height: 74, color: WidgetPalette.gold, rank: 1) }
            if entries.count >= 3 { PodiumColumn(entry: entries[2], height: 40, color: WidgetPalette.warning, rank: 3) }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PodiumColumn: View {
    @Environment(\.colorScheme) private var scheme
    let entry: WidgetSnapshot.BackendData.LeaderEntry
    let height: CGFloat
    let color: Color
    let rank: Int

    private var initials: String {
        let parts = entry.displayName.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)) }.joined().uppercased()
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle().fill(color.opacity(0.22))
                Circle().stroke(color, lineWidth: entry.currentUser ? 2 : 0.5)
                Text(initials)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color)
            }
            .frame(width: 30, height: 30)

            Text(entry.displayName)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.85))
                .frame(height: height)
                .overlay(
                    VStack(spacing: 1) {
                        Text("\(rank)")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(.white)
                        Text("\(entry.score)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                )
        }
        .frame(maxWidth: .infinity)
    }
}

private struct LeaderRow: View {
    @Environment(\.colorScheme) private var scheme
    let rank: Int
    let entry: WidgetSnapshot.BackendData.LeaderEntry

    var body: some View {
        HStack(spacing: 10) {
            Text("#\(rank)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                .frame(width: 22, alignment: .leading)
            Text(entry.displayName)
                .font(.system(size: 11, weight: entry.currentUser ? .bold : .medium))
                .foregroundStyle(entry.currentUser ? WidgetPalette.accent : .primary)
                .lineLimit(1)
            Spacer()
            Text("\(entry.score)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(entry.currentUser
                      ? WidgetPalette.accent.opacity(0.1)
                      : (scheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03)))
        )
    }
}
