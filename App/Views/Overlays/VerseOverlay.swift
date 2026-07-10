import SwiftUI

/// Verse mode — double-tapping the header flower fades out the header buttons and
/// slots this compact ticker into the trailing region where they were. It walks
/// through seven proverbs on wisdom, wealth, and the noble woman, one small slide
/// at a time, auto-advancing with a gentle cross-fade. Tap the text to skip ahead;
/// double-tap the flower again to leave. Lives inline in RootView's header row —
/// not a full-screen overlay.
struct HeaderVerseTicker: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var index = 0
    /// Bumped on tap to restart the dwell timer (`.task(id:)`) so the tapped
    /// slide gets a full read before the next auto-advance.
    @State private var cycle = 0

    static let tickerWidth: CGFloat = 180
    static let tickerHeight: CGFloat = 56   // fits 3 lines of bloomBody(12.5); fixed so slides don't jitter the header
    static let slideSeconds: Double = 4.5
    /// Word-boundary budget per slide. ~72 chars ≈ 3 lines of bloomBody(12.5) in a
    /// ~180pt trailing region; minimumScaleFactor(0.9) is the safety net if a slide
    /// runs long.
    static let charBudget = 72

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

    /// One rendered card: either a verse chunk (≤3 lines) or a verse's closing
    /// reference line. Flattened across all seven verses; looping back to slide 0
    /// naturally carries verse 7 → verse 1.
    struct Slide: Equatable {
        let text: String
        let isRef: Bool
    }

    static let allSlides: [Slide] = verses.flatMap { verse in
        Self.chunk(verse.text, budget: Self.charBudget).map { Slide(text: $0, isRef: false) }
            + [Slide(text: verse.ref, isRef: true)]
    }

    /// Splits `text` into word-boundary slices, each at most `budget` characters —
    /// as many as the whole verse needs. Pure: no view, no state.
    static func chunk(_ text: String, budget: Int) -> [String] {
        var slides: [String] = []
        var current = ""
        for word in text.split(separator: " ") {
            if current.isEmpty {
                current = String(word)
            } else if current.count + 1 + word.count <= budget {
                current += " " + word
            } else {
                slides.append(current)
                current = String(word)
            }
        }
        if !current.isEmpty { slides.append(current) }
        return slides.isEmpty ? [text] : slides
    }

    var body: some View {
        let slide = Self.allSlides[index]
        // ZStack is the stable host: `.task` lives here so a slide change (which
        // swaps the `.id`-tagged Text inside) never restarts the dwell timer.
        return ZStack {
            Text(slide.text)
                .font(slide.isRef ? bloomBody(10.5, weight: .semibold)
                                  : bloomBody(12.5, weight: .medium).italic())
                .foregroundStyle(theme.color(slide.isRef ? "muted" : "text"))
                .lineLimit(3)
                .minimumScaleFactor(0.9)
                .multilineTextAlignment(.trailing)
                .lineSpacing(2)
                .id(index)
                .transition(.opacity)
        }
        .frame(width: Self.tickerWidth, height: Self.tickerHeight, alignment: .trailing)
        .contentShape(Rectangle())
        .onTapGesture { advanceByTap() }
        // `.task` runs while the ticker is mounted and is cancelled automatically
        // when it leaves the tree (verse mode off == view disappears). Changing
        // `cycle` (on tap) cancels + restarts it with a fresh dwell. No manual
        // Timer, so nothing to leak.
        .task(id: cycle) { await run() }
        .accessibilityElement()
        .accessibilityLabel(slide.text)
        .accessibilityAddTraits(.isButton)
    }

    private func run() async {
        guard Self.allSlides.count > 1 else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Self.slideSeconds))
            guard !Task.isCancelled else { break }
            advance(animated: !reduceMotion)
        }
    }

    private func advanceByTap() {
        advance(animated: !reduceMotion)
        cycle += 1   // restart the dwell so the tapped slide gets a full read
    }

    private func advance(animated: Bool) {
        let next = (index + 1) % Self.allSlides.count
        if animated {
            withAnimation(.easeInOut(duration: 0.6)) { index = next }
        } else {
            index = next   // Reduce Motion: hard swap, still readable
        }
    }
}
