import AVFoundation
import SwiftUI

// MARK: - Mentor Character + Chat Bubble

/// A walking mentor character at the bottom of the window with a floating chat bubble.
struct MentorCharacterView: View {
    @ObservedObject var backend: HabitBackendStore
    @Binding var nudge: String?
    @State private var walker = WalkerState()
    @State private var chatOpen = false
    @State private var chatShown = false
    @State private var chatAnimationTask: Task<Void, Never>? = nil
    @State private var messageText = ""
    @State private var hasUnread = false
    @State private var visibleNudge: String? = nil
    @State private var nudgeShown = false
    @State private var nudgeDismissTask: Task<Void, Never>? = nil

    private let characterHeight: CGFloat = 130
    private let videoAspect: CGFloat = 1080 / 1920

    private var mentorName: String {
        backend.dashboard?.match?.mentor.displayName ?? "Mentor"
    }

    private var messages: [AccountabilityDashboard.Message] {
        backend.messages(matchID: backend.dashboard?.match?.id)
    }

    private let bubbleHeight: CGFloat = 300
    private let bubbleWidth: CGFloat = 280
    private let bubbleGap: CGFloat = 8
    private let nudgeBubbleWidth: CGFloat = 180

    var body: some View {
        GeometryReader { geo in
            let charWidth = characterHeight * videoAspect
            let travelDistance = max(geo.size.width - charWidth, 0)
            let charX = walker.positionProgress * travelDistance
            let characterHeadX = charX + charWidth / 2
            // The visible character occupies ~85% of the frame (bottom 15% is ground offset)
            let visibleCharTop = characterHeight * 0.85

            LoopingVideoView(videoName: "walk-bruce-01", isPlaying: walker.isWalking)
                .frame(width: charWidth, height: characterHeight)
                .scaleEffect(x: walker.goingRight ? 1 : -1, y: 1, anchor: .center)
                .position(
                    x: charX + charWidth / 2,
                    y: geo.size.height - characterHeight / 2 + characterHeight * 0.15
                )
                .onTapGesture {
                    toggleChat()
                }

            if hasUnread && !chatOpen {
                Circle()
                    .fill(.red)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Text("\(messages.count)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .position(
                        x: charX + charWidth - 4,
                        y: geo.size.height - visibleCharTop - 4
                    )
            }

            // Chat bubble — positioned just above the character's head
            if chatOpen {
                let bubbleY = geo.size.height - visibleCharTop - bubbleGap - bubbleHeight / 2
                let bubbleCenterX = characterHeadX
                let clampedX = clamped(bubbleCenterX, lowerBound: bubbleWidth / 2 + 8, upperBound: geo.size.width - bubbleWidth / 2 - 8)
                let anchorX = (bubbleCenterX - (clampedX - bubbleWidth / 2)) / bubbleWidth
                let scaleAnchor = UnitPoint(x: clamped(anchorX, lowerBound: 0, upperBound: 1), y: 1)

                MentorChatBubble(
                    mentorName: mentorName,
                    isAI: backend.dashboard?.match?.aiMentor ?? false,
                    messages: messages,
                    messageText: $messageText,
                    onSend: sendMessage,
                    onClose: {
                        closeChat()
                    }
                )
                .frame(width: bubbleWidth, height: bubbleHeight)
                .scaleEffect(chatShown ? 1 : 0.05, anchor: scaleAnchor)
                .opacity(chatShown ? 1 : 0)
                .position(x: clampedX, y: bubbleY)
                .animation(.spring(response: 0.35, dampingFraction: 0.78), value: chatShown)
                .zIndex(10)
            }

            if let text = visibleNudge {
                let nudgeCenterX = clamped(
                    characterHeadX,
                    lowerBound: nudgeBubbleWidth / 2 + 8,
                    upperBound: geo.size.width - nudgeBubbleWidth / 2 - 8
                )
                let nudgeAnchorX = (characterHeadX - (nudgeCenterX - nudgeBubbleWidth / 2)) / nudgeBubbleWidth
                let clampedNudgeAnchorX = clamped(nudgeAnchorX, lowerBound: 0, upperBound: 1)
                let nudgeAnchor = UnitPoint(x: clampedNudgeAnchorX, y: 1)
                let nudgeBubbleY = geo.size.height - visibleCharTop - bubbleGap - 22

                SpeechBubbleNudge(text: text, width: nudgeBubbleWidth, tailAnchorX: clampedNudgeAnchorX)
                    .scaleEffect(nudgeShown ? 1 : 0.01, anchor: nudgeAnchor)
                    .opacity(nudgeShown ? 1 : 0)
                    .position(x: nudgeCenterX, y: nudgeBubbleY)
                    .animation(.spring(response: 0.3, dampingFraction: 0.65), value: nudgeShown)
                    .zIndex(11)
                    .allowsHitTesting(false)
            }

            Color.clear
                .onAppear {
                    walker.travelDistance = travelDistance
                    walker.start()
                }
                .onChange(of: geo.size.width) { _, _ in
                    walker.travelDistance = travelDistance
                }
                .onChange(of: messages.count) { old, new in
                    if new > old && !chatOpen {
                        hasUnread = true
                    }
                }
                .onChange(of: nudge) { _, newValue in
                    guard let msg = newValue else { return }
                    nudgeDismissTask?.cancel()
                    nudge = nil
                    visibleNudge = msg
                    nudgeShown = false
                    DispatchQueue.main.async {
                        nudgeShown = true
                    }
                    nudgeDismissTask = Task {
                        try? await Task.sleep(for: .seconds(2))
                        guard !Task.isCancelled else { return }
                        await MainActor.run {
                            nudgeShown = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                visibleNudge = nil
                            }
                        }
                    }
                }
        }
        .frame(height: chatOpen ? characterHeight + bubbleHeight + bubbleGap : characterHeight)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: chatOpen)
    }

    private func toggleChat() {
        if chatOpen {
            closeChat()
        } else {
            openChat()
        }
    }

    private func openChat() {
        chatAnimationTask?.cancel()
        hasUnread = false
        chatShown = false

        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            chatOpen = true
        }

        Task {
            await backend.markMatchRead(matchID: backend.dashboard?.match?.id)
        }

        chatAnimationTask = Task {
            await Task.yield()
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    chatShown = true
                }
            }
        }
    }

    private func closeChat() {
        chatAnimationTask?.cancel()

        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            chatShown = false
        }

        chatAnimationTask = Task {
            try? await Task.sleep(for: .milliseconds(180))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    chatOpen = false
                }
            }
        }
    }

    private func clamped(_ value: CGFloat, lowerBound: CGFloat, upperBound: CGFloat) -> CGFloat {
        min(max(value, lowerBound), upperBound)
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard let matchID = backend.dashboard?.match?.id else { return }
        messageText = ""

        Task {
            await backend.sendMenteeMessage(matchId: matchID, message: text)
        }
    }
}

// MARK: - Mentee Character + Chat Bubble

/// A walking mentee character — visually distinct from the mentor (purple tint, offset start).
/// Represents a person the current user is mentoring in the social hub.
struct MenteeCharacterView: View {
    @ObservedObject var backend: HabitBackendStore
    let mentorMissedCount: Int
    @State private var walker = WalkerState()
    @State private var chatOpen = false
    @State private var chatShown = false
    @State private var chatAnimationTask: Task<Void, Never>? = nil
    @State private var hasAttention = false

    private let characterHeight: CGFloat = 130
    private let videoAspect: CGFloat = 1080 / 1920

    private var mentee: AccountabilityDashboard.MenteeSummary? {
        backend.dashboard?.mentorDashboard.mentees.first
    }

    private let bubbleHeight: CGFloat = 252
    private let bubbleWidth: CGFloat = 260
    private let bubbleGap: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let charWidth = characterHeight * videoAspect
            let travelDistance = max(geo.size.width - charWidth, 0)
            let charX = walker.positionProgress * travelDistance
            let characterHeadX = charX + charWidth / 2
            let visibleCharTop = characterHeight * 0.85

            // Jazz — the orange lil-agent character
            LoopingVideoView(videoName: "walk-jazz-01", isPlaying: walker.isWalking)
                .frame(width: charWidth, height: characterHeight)
                .scaleEffect(x: walker.goingRight ? 1 : -1, y: 1, anchor: .center)
            .position(
                x: charX + charWidth / 2,
                y: geo.size.height - characterHeight / 2 + characterHeight * 0.15
            )
            .onTapGesture { toggleChat() }

            // Attention badge when mentee missed habits today
            if hasAttention && !chatOpen {
                Circle()
                    .fill(.orange)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Image(systemName: "exclamationmark")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.white)
                    )
                    .position(
                        x: charX + charWidth - 4,
                        y: geo.size.height - visibleCharTop - 4
                    )
            }

            // Mentor missed count badge — shown when any mentee has missed habits today
            if mentorMissedCount > 0 && !chatOpen {
                ZStack {
                    Circle()
                        .fill(CleanShotTheme.warning)
                    Text("\(mentorMissedCount)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 18, height: 18)
                .position(
                    x: charX + 4,
                    y: geo.size.height - visibleCharTop - 4
                )
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: mentorMissedCount)
            }

            // Chat bubble anchored above the character's head
            if chatOpen {
                let bubbleY = geo.size.height - visibleCharTop - bubbleGap - bubbleHeight / 2
                let clampedX = clamped(characterHeadX, lowerBound: bubbleWidth / 2 + 8, upperBound: geo.size.width - bubbleWidth / 2 - 8)
                let anchorX = (characterHeadX - (clampedX - bubbleWidth / 2)) / bubbleWidth
                let scaleAnchor = UnitPoint(x: clamped(anchorX, lowerBound: 0, upperBound: 1), y: 1)

                if let mentee {
                    MenteeChatBubble(mentee: mentee, onSend: sendMessage, onClose: closeChat)
                        .frame(width: bubbleWidth, height: bubbleHeight)
                        .scaleEffect(chatShown ? 1 : 0.05, anchor: scaleAnchor)
                        .opacity(chatShown ? 1 : 0)
                        .position(x: clampedX, y: bubbleY)
                        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: chatShown)
                        .zIndex(10)
                }
            }

            Color.clear
                .onAppear {
                    // Start mentee on the right side so they walk toward the mentor
                    walker.positionProgress = 0.7
                    walker.goingRight = false
                    walker.travelDistance = travelDistance
                    walker.start()
                    hasAttention = (mentee?.missedHabitsToday ?? 0) > 0
                }
                .onChange(of: geo.size.width) { _, _ in
                    walker.travelDistance = travelDistance
                }
                .onChange(of: mentee?.missedHabitsToday ?? 0) { _, new in
                    if !chatOpen { hasAttention = new > 0 }
                }
        }
        .frame(height: chatOpen ? characterHeight + bubbleHeight + bubbleGap : characterHeight)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: chatOpen)
    }

    private func toggleChat() { chatOpen ? closeChat() : openChat() }

    private func openChat() {
        chatAnimationTask?.cancel()
        hasAttention = false
        chatShown = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) { chatOpen = true }
        chatAnimationTask = Task {
            await Task.yield()
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) { chatShown = true }
            }
        }
    }

    private func closeChat() {
        chatAnimationTask?.cancel()
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) { chatShown = false }
        chatAnimationTask = Task {
            try? await Task.sleep(for: .milliseconds(180))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) { chatOpen = false }
            }
        }
    }

    private func sendMessage(_ text: String) async {
        guard let matchId = mentee?.matchId else { return }
        await backend.sendMenteeMessage(matchId: matchId, message: text)
    }

    private func clamped(_ value: CGFloat, lowerBound: CGFloat, upperBound: CGFloat) -> CGFloat {
        min(max(value, lowerBound), upperBound)
    }
}

// MARK: - Mentor Alert Banner

/// Shown above the mentee character when any mentees have missed habits today.
struct MentorAlertBanner: View {
    let missedCount: Int
    let mentees: [AccountabilityDashboard.MenteeSummary]
    let onNudge: (Int64) -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var menteesWithMissed: [AccountabilityDashboard.MenteeSummary] {
        mentees.filter { $0.missedHabitsToday > 0 }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CleanShotTheme.warning)

            Text("\(menteesWithMissed.count) mentee\(menteesWithMissed.count == 1 ? "" : "s") need a nudge today")
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            Spacer()

            // Send nudge buttons per mentee with missed habits
            ForEach(menteesWithMissed.prefix(3)) { mentee in
                Button {
                    onNudge(mentee.matchId)
                } label: {
                    HStack(spacing: 4) {
                        Text(mentee.displayName)
                            .lineLimit(1)
                            .frame(maxWidth: 60)
                        Image(systemName: "hand.wave.fill")
                    }
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)
                .tint(CleanShotTheme.warning)
                .controlSize(.mini)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark
                      ? CleanShotTheme.warning.opacity(0.15)
                      : CleanShotTheme.warning.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(CleanShotTheme.warning.opacity(0.3), lineWidth: 0.8)
                )
        )
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.1), radius: 8, y: 2)
    }
}
