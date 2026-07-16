import SwiftUI

/// The "Load chords" control, reimagined as a slide-to-bloom: drag the flower
/// thumb across the track and the chords load in a burst of petals. Tapping the
/// track nudges the thumb to teach the gesture; VoiceOver gets a plain button.
struct SlideToBloom: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var enabled: Bool
    var onLoad: () -> Void

    @State private var dragX: CGFloat = 0
    @State private var isDragging = false
    @State private var bloomed = false        // brief success state at the far end
    @State private var successTrigger = 0     // haptic + reset timing
    @State private var resetGeneration = 0

    private let height: CGFloat = 60
    private let thumbSize: CGFloat = 50
    private let inset: CGFloat = 5

    var body: some View {
        GeometryReader { geo in
            let maxX = max(1, geo.size.width - thumbSize - inset * 2)
            let progress = min(1, dragX / maxX)

            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(theme.color("surfaceSoft"))
                    .overlay(Capsule().stroke(theme.color("line"), lineWidth: 1))

                // Fill grows behind the thumb as it travels
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [theme.color("primary").opacity(0.35), theme.color("primary").opacity(0.75)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: dragX + thumbSize + inset * 2)
                    .opacity(progress > 0.01 ? 1 : 0)

                // Hint label fades as the thumb travels
                HStack(spacing: 6) {
                    Text(enabled ? "Slide to load your chords" : "Pick a song or write chords first")
                        .font(bloomBody(14, weight: .semibold))
                        .foregroundStyle(theme.color(enabled ? "deep" : "muted"))
                    if enabled {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(theme.color("primaryStrong"))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(theme.color("primaryStrong").opacity(0.45))
                    }
                }
                .frame(maxWidth: .infinity)
                .opacity(1 - Double(progress) * 1.6)

                // Flower thumb
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.color("primary"), theme.color("primaryStrong")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: theme.color("shadow"), radius: isDragging ? 10 : 5, y: 3)
                    Image(systemName: bloomed ? "checkmark" : "camera.macro")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(Double(progress) * 180))
                        .scaleEffect(bloomed ? 1.2 : 1)
                }
                .frame(width: thumbSize, height: thumbSize)
                .scaleEffect(isDragging ? 1.06 : 1)
                .offset(x: inset + dragX)
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            guard enabled, !bloomed else { return }
                            isDragging = true
                            dragX = min(maxX, max(0, value.translation.width))
                        }
                        .onEnded { _ in
                            isDragging = false
                            guard enabled, !bloomed else { return }
                            if dragX > maxX * 0.85 {
                                complete(maxX: maxX)
                            } else {
                                withAnimation(BloomMotion.springSoft) { dragX = 0 }
                            }
                        }
                )
            }
            .contentShape(Capsule())
            .onTapGesture {
                guard enabled, !bloomed, !isDragging else { return }
                nudge(maxX: maxX)
            }
        }
        .frame(height: height)
        .opacity(enabled ? 1 : 0.55)
        .animation(.easeOut(duration: 0.25), value: enabled)
        .sensoryFeedback(.success, trigger: successTrigger)
        // VoiceOver skips the gesture entirely: one honest button.
        .accessibilityRepresentation {
            Button("Load chords") { if enabled { onLoad() } }
        }
    }

    /// Ride the thumb home, bloom, fire the load, then glide back for next time.
    private func complete(maxX: CGFloat) {
        successTrigger += 1
        withAnimation(BloomMotion.springSoft) {
            dragX = maxX
            bloomed = true
        }
        onLoad()
        resetGeneration += 1
        let expected = resetGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            guard resetGeneration == expected else { return }
            withAnimation(BloomMotion.springSoft) {
                dragX = 0
                bloomed = false
            }
        }
    }

    /// A tap on the track teaches the gesture: the thumb hops forward and settles
    /// back. Under reduce-motion the tap just loads (no lesson, no barrier).
    private func nudge(maxX: CGFloat) {
        if reduceMotion || !theme.motionEnabled {
            complete(maxX: maxX)
            return
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { dragX = min(maxX, 34) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            guard !isDragging, !bloomed else { return }
            withAnimation(BloomMotion.springSoft) { dragX = 0 }
        }
    }
}
