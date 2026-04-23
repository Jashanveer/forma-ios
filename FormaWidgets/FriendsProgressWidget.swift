import SwiftUI
import WidgetKit

struct FriendsProgressWidget: Widget {
    let kind = "FriendsProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotTimelineProvider()) { entry in
            FriendsProgressView(snapshot: entry.snapshot)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName("Friends Progress")
        .description("See how your circle is doing today.")
        .supportedFamilies([.systemMedium])
    }
}

private struct FriendsProgressView: View {
    @Environment(\.colorScheme) private var scheme
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(WidgetPalette.cyan)
                    Text("Friends")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)
                }
                Spacer()
                if let count = snapshot.backend?.friendCount {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(WidgetPalette.subtleForeground(scheme))
                }
            }

            if let friends = snapshot.backend?.friends, !friends.isEmpty {
                VStack(spacing: 6) {
                    ForEach(friends.prefix(3)) { friend in
                        FriendRow(friend: friend)
                    }
                }
            } else {
                Spacer()
                Text(snapshot.backend == nil ? "Sign in to see friends" : "Add friends to get started")
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

private struct FriendRow: View {
    @Environment(\.colorScheme) private var scheme
    let friend: WidgetSnapshot.BackendData.FriendCard

    private var initials: String {
        let parts = friend.displayName.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)) }.joined().uppercased()
    }

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(WidgetPalette.accent.opacity(0.18))
                Text(initials)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(WidgetPalette.accent)
            }
            .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(friend.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(WidgetPalette.trackColor(scheme))
                        Capsule()
                            .fill(Color.bar(pct: Double(friend.progressPercent) / 100, scheme: scheme))
                            .frame(width: geo.size.width * CGFloat(friend.progressPercent) / 100)
                    }
                }
                .frame(height: 4)
            }

            Text("\(friend.progressPercent)%")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 32, alignment: .trailing)
        }
    }
}
