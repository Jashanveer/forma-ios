import SwiftUI
import WidgetKit

struct XPLevelWidget: Widget {
    let kind = "XPLevelWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotTimelineProvider()) { entry in
            XPLevelView(snapshot: entry.snapshot)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName("XP & Level")
        .description("Your current level, XP, and weekly consistency.")
        .supportedFamilies([.systemSmall])
    }
}

private struct XPLevelView: View {
    @Environment(\.colorScheme) private var scheme
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(WidgetPalette.violet)
                Text("Level")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                Spacer()
            }

            if let backend = snapshot.backend {
                Text(backend.levelName)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 9))
                        .foregroundStyle(WidgetPalette.gold)
                    Text("\(backend.xp) XP")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.primary)
                }

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Consistency")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                        Spacer()
                        Text("\(backend.weeklyConsistencyPercent)%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.primary)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(WidgetPalette.trackColor(scheme))
                            Capsule()
                                .fill(WidgetPalette.violet)
                                .frame(width: geo.size.width * CGFloat(backend.weeklyConsistencyPercent) / 100)
                        }
                    }
                    .frame(height: 5)
                }

                HStack(spacing: 8) {
                    CapsuleStat(icon: "snowflake", value: "\(backend.freezesAvailable)", tint: WidgetPalette.cyan)
                    CapsuleStat(icon: "checkmark.circle.fill", value: "\(backend.checksToday)/\(backend.dailyCap)", tint: WidgetPalette.success)
                }
            } else {
                Spacer()
                Text("Sign in to see your level")
                    .font(.system(size: 11))
                    .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                Spacer()
            }
        }
        .padding(14)
    }
}

private struct CapsuleStat: View {
    @Environment(\.colorScheme) private var scheme
    let icon: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Capsule().fill(tint.opacity(0.12)))
        .overlay(Capsule().stroke(tint.opacity(0.3), lineWidth: 0.5))
    }
}
