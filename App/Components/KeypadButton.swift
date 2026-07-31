import SwiftUI
import BloomCore

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
            // Tracks the key instead of sitting at a flat 22pt — on a 6.9" phone that
            // read as a speck floating in the disc. minimumScaleFactor absorbs the wide
            // labels ("+/−") rather than letting them push past the circle's edge.
            .font(bloomNumber(KeypadLayout.labelFont(keyHeight: height), weight: .medium))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundStyle(labelColor)
            // Circle: an EXACT height×height square (maxWidth alone would let a
            // narrow glyph collapse the face into a pill), so fill, clip,
            // shimmer, and glyph all share one true disc. Soft: full cell width.
            .frame(width: isCircle ? height : nil)
            .frame(maxWidth: isCircle ? nil : .infinity)
            .frame(height: height)
            .bloomKeyGlass(tint: backgroundColor, cornerRadius: faceCornerRadius)
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

/// Liquid Glass key faces, shared by the portrait keypad and the landscape scientific
/// pad so the whole keyboard is one material.
///
/// The theme's key colours are fully opaque brand pinks; tinting glass with them at full
/// strength would just repaint the flat button and throw away the refraction. Tinting at
/// `glassTintStrength` keeps the palette recognisable while the glass still reads.
// ponytail: one tint strength for every key. It is the knob — glass over a busy petal
// background may want it lower, over a flat theme higher.
private let glassTintStrength: Double = 0.5

extension View {
    /// iOS 26+ gets real Liquid Glass; everything back to the iOS 17 deployment target
    /// keeps the flat fill it has today.
    @ViewBuilder
    func bloomKeyGlass(tint: Color, cornerRadius: CGFloat) -> some View {
        // compiler guard as well as #available: `.glassEffect` does not exist in SDKs
        // before Xcode 26, so without this the project fails to BUILD on an older
        // toolchain rather than merely falling back at runtime.
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            self.glassEffect(
                .regular.tint(tint.opacity(glassTintStrength)).interactive(),
                in: .rect(cornerRadius: cornerRadius)
            )
        } else {
            self.bloomFlatKeyFace(tint: tint, cornerRadius: cornerRadius)
        }
        #else
        self.bloomFlatKeyFace(tint: tint, cornerRadius: cornerRadius)
        #endif
    }

    /// The pre-26 key face, and the fallback the glass path falls back to.
    func bloomFlatKeyFace(tint: Color, cornerRadius: CGFloat) -> some View {
        background(tint)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
