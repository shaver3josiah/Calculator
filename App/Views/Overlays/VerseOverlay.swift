import SwiftUI

/// Verse mode — double-tapping the header flower opens this serene, swipeable
/// gallery of seven proverbs on wisdom, wealth, and the noble woman. Full-screen
/// overlay (lives in RootView's overlays ZStack). Dismiss by tapping the flower,
/// the Close affordance, or swiping down.
struct VerseOverlay: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(SoundStore.self) private var sound
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isPresented: Bool

    @State private var page = 0
    @State private var dragOffset: CGFloat = 0

    /// Berean Standard Bible wording (verified verbatim against biblehub.com/bsb).
    static let verses: [(text: String, ref: String)] = [
        ("She appraises a field and buys it; from her earnings she plants a vineyard.",
         "— Proverbs 31:16 (BSB)"),
        ("She sees that her gain is good, and her lamp is not extinguished at night.",
         "— Proverbs 31:18 (BSB)"),
        ("She makes linen garments and sells them; she delivers sashes to the merchants.",
         "— Proverbs 31:24 (BSB)"),
        ("Strength and honor are her clothing, and she can laugh at the days to come.",
         "— Proverbs 31:25 (BSB)"),
        ("Blessed is the man who finds wisdom, the man who acquires understanding, for she is more profitable than silver, and her gain is better than fine gold.",
         "— Proverbs 3:13-14 (BSB)"),
        ("Receive my instruction instead of silver, and knowledge rather than pure gold. For wisdom is more precious than rubies, and nothing you desire compares with her.",
         "— Proverbs 8:10-11 (BSB)"),
        ("How much better to acquire wisdom than gold! To gain understanding is more desirable than silver.",
         "— Proverbs 16:16 (BSB)")
    ]

    var body: some View {
        if isPresented {
            content
                .transition(.opacity)
        }
    }

    private var content: some View {
        ZStack {
            theme.color("bg").opacity(0.97)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Capsule()
                    .fill(theme.color("muted").opacity(0.28))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)

                FlowerLogo(size: 46)
                    .contentShape(Rectangle())
                    .onTapGesture { dismiss() }

                TabView(selection: $page) {
                    ForEach(Self.verses.indices, id: \.self) { i in
                        verseCard(Self.verses[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                dots

                Button(action: dismiss) {
                    Text("Close")
                        .font(bloomBody(13, weight: .semibold))
                        .foregroundStyle(theme.color("muted"))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 14)
            }
            .padding(.horizontal, 24)
        }
        .offset(y: dragOffset)
        .simultaneousGesture(swipeDown)
    }

    private func verseCard(_ verse: (text: String, ref: String)) -> some View {
        VStack(spacing: 22) {
            Spacer(minLength: 0)
            Text(verse.text)
                .font(bloomBody(19))
                .italic()
                .foregroundStyle(theme.color("text"))
                .multilineTextAlignment(.center)
                .lineSpacing(7)
            Text(verse.ref)
                .font(bloomBody(12, weight: .semibold))
                .foregroundStyle(theme.color("muted"))
            Spacer(minLength: 0)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
                .fill(theme.color("surface"))
                .shadow(color: theme.color("shadow"), radius: 22, y: 10)
        )
        .overlay {
            if theme.shimmerOn {
                EncircleOutline(trigger: page, cornerRadius: theme.radius)
            }
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 2)
    }

    private var dots: some View {
        HStack(spacing: 8) {
            ForEach(Self.verses.indices, id: \.self) { i in
                Circle()
                    .fill(theme.color(i == page ? "primaryStrong" : "muted"))
                    .opacity(i == page ? 1 : 0.35)
                    .frame(width: i == page ? 8 : 6, height: i == page ? 8 : 6)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: page)
            }
        }
    }

    private var swipeDown: some Gesture {
        DragGesture(minimumDistance: 24)
            .onChanged { value in
                if value.translation.height > 0,
                   value.translation.height > abs(value.translation.width) {
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                if value.translation.height > 90,
                   value.translation.height > abs(value.translation.width) {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        dragOffset = 0
                    }
                }
            }
    }

    private func dismiss() {
        sound.play("modeswitch")
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            dragOffset = 0
            isPresented = false
        }
    }
}
