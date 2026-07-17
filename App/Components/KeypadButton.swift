import SwiftUI

struct KeypadButton: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(SoundStore.self) private var soundStore

    var label: String
    var soundEvent: String
    var isAccent: Bool = false
    var isStrong: Bool = false
    var isPending: Bool = false   // queued operator: invert to the strong style until next digit
    var height: CGFloat = 58   // compresses on small phones so the grid never clips
    var action: () -> Void

    @State private var isPressed = false
    @State private var feedbackTrigger = false

    var body: some View {
        Button {
            feedbackTrigger.toggle()
            action()
        } label: {
            // Circle style shrinks the visible face to a height-diameter disc,
            // but the tap target stays the full flexible cell so thumbs don't miss.
            keyFace
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .sensoryFeedback(.impact(weight: .light), trigger: feedbackTrigger) { _, _ in
            soundStore.hapticsEnabled
        }
    }

    // Reading themeStore.keyStyle here (called from body) keeps the switch live.
    private var isCircle: Bool { themeStore.keyStyle == "circle" }

    private var faceCornerRadius: CGFloat {
        isCircle ? height / 2 : themeStore.radius * 0.6
    }

    private var keyFace: some View {
        Text(label)
            .font(bloomNumber(22, weight: .medium))
            .foregroundStyle(labelColor)
            // Circle: an EXACT height×height square (maxWidth alone would let a
            // narrow glyph collapse the face into a pill), so fill, clip,
            // shimmer, and glyph all share one true disc. Soft: full cell width.
            .frame(width: isCircle ? height : nil)
            .frame(maxWidth: isCircle ? nil : .infinity)
            .frame(height: height)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: faceCornerRadius))
            .overlay {
                if themeStore.shimmerOn {
                    ZStack {
                        if isStrong {   // "=" is the one hero CTA — a slow ambient glint
                            AmbientShimmer(cornerRadius: faceCornerRadius)
                        }
                        ShimmerSweep(
                            trigger: feedbackTrigger,
                            intense: isStrong || isAccent,   // darker-pink keys shine more
                            cornerRadius: faceCornerRadius
                        )
                    }
                }
            }
    }

    private var backgroundColor: Color {
        if isStrong || isPending { return themeStore.color("primaryStrong") }
        if isAccent { return themeStore.color("surface2") }
        return themeStore.color("surfaceSoft")
    }

    private var labelColor: Color {
        if isStrong || isPending { return .white }
        return themeStore.color("text")
    }
}
