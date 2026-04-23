import SwiftUI
import WidgetKit

struct MenteeViewWidget: Widget {
    let kind = "MenteeViewWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotTimelineProvider()) { entry in
            MenteeViewContent(snapshot: entry.snapshot)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName("Mentor Tip")
        .description("Your mentor's latest note and today's missed habits.")
        .supportedFamilies([.systemMedium])
    }
}

private struct MenteeViewContent: View {
    @Environment(\.colorScheme) private var scheme
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let mentor = snapshot.backend?.mentor {
                HStack(spacing: 10) {
                    MentorAvatar(name: mentor.displayName)
                        .frame(width: 36, height: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mentor.displayName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.primary)
                        Text("Mentor · \(mentor.consistencyPercent)% consistency")
                            .font(.system(size: 9))
                            .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                    }
                    Spacer()
                    StatusChip(missed: mentor.missedHabitsToday)
                }

                Text(mentor.tip)
                    .font(.system(size: 11))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(WidgetPalette.violet.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(WidgetPalette.violet.opacity(0.25), lineWidth: 0.6)
                    )

                HStack(spacing: 10) {
                    MiniStat(label: "Progress", value: "\(mentor.progressScore)", tint: WidgetPalette.success)
                    MiniStat(label: "Streak", value: "\(snapshot.currentPerfectStreak)d", tint: WidgetPalette.warning)
                    Spacer()
                }
            } else {
                Spacer()
                Text(snapshot.backend == nil ? "Sign in to meet your mentor" : "No mentor paired yet")
                    .font(.system(size: 11))
                    .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

private struct MentorAvatar: View {
    let name: String
    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)) }.joined().uppercased()
    }
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [WidgetPalette.violet, WidgetPalette.accent],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            Text(initials)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

private struct StatusChip: View {
    let missed: Int
    var body: some View {
        let tint = missed == 0 ? WidgetPalette.success : WidgetPalette.warning
        return HStack(spacing: 3) {
            Image(systemName: missed == 0 ? "checkmark" : "exclamationmark.triangle.fill")
                .font(.system(size: 8, weight: .bold))
            Text(missed == 0 ? "On track" : "\(missed) missed")
                .font(.system(size: 9, weight: .semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(tint.opacity(0.12)))
    }
}

private struct MiniStat: View {
    @Environment(\.colorScheme) private var scheme
    let label: String
    let value: String
    let tint: Color
    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tint)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(WidgetPalette.subtleForeground(scheme))
        }
    }
}
