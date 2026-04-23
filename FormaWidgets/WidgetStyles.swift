import SwiftUI
import WidgetKit

/// Shared palette and primitives for the Forma widgets.
/// Colours mirror the design spec (dark-first, light-mode-aware via Color.primary).
enum WidgetPalette {
    static let accent  = Color(red: 46/255,  green: 148/255, blue: 219/255)
    static let success = Color(red: 56/255,  green: 173/255, blue: 92/255)
    static let warning = Color(red: 245/255, green: 156/255, blue: 46/255)
    static let gold    = Color(red: 240/255, green: 189/255, blue: 61/255)
    static let violet  = Color(red: 117/255, green: 122/255, blue: 214/255)
    static let cyan    = Color(red: 50/255,  green: 173/255, blue: 230/255)

    static func trackColor(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.07)
    }

    static func subtleForeground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.38) : Color.black.opacity(0.4)
    }
}

/// SwiftUI progress ring matching the design's arc.
struct ProgressRing<Label: View>: View {
    let progress: Double
    let lineWidth: CGFloat
    let tint: Color
    let track: Color
    @ViewBuilder let label: () -> Label

    init(progress: Double, lineWidth: CGFloat, tint: Color, track: Color, @ViewBuilder label: @escaping () -> Label = { EmptyView() }) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.tint = tint
        self.track = track
        self.label = label
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            label()
        }
    }
}

/// Thin wrapper that paints the widget's inner gradient + border to match the design.
struct WidgetBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        LinearGradient(
            colors: scheme == .dark
                ? [Color(red: 42/255, green: 44/255, blue: 52/255), Color(red: 28/255, green: 30/255, blue: 36/255)]
                : [Color.white, Color(red: 240/255, green: 243/255, blue: 248/255)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Color {
    static func bar(pct: Double, scheme: ColorScheme) -> Color {
        if pct >= 1.0 { return WidgetPalette.success }
        if pct >= 0.7 { return WidgetPalette.accent }
        if pct >= 0.4 { return WidgetPalette.warning }
        return WidgetPalette.trackColor(scheme)
    }
}
