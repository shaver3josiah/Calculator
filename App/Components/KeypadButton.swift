import SwiftUI
import UIKit
import CoreText
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
        let fontSize = KeypadLayout.labelFont(keyHeight: height)
        return Text(label)
            // Tracks the key instead of sitting at a flat 22pt — on a 6.9" phone that
            // read as a speck floating in the disc. minimumScaleFactor absorbs the wide
            // labels ("+/−") rather than letting them push past the circle's edge.
            .font(bloomNumber(fontSize, weight: .medium))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundStyle(labelColor)
            // Centre the label's INK in the disc, not its line box — Playfair's old-style
            // figures otherwise leave 6/8 riding high and 3/7/9 hanging low. Layout is
            // untouched (offset is draw-time only), so the tap target does not move.
            .offset(y: OpticalCenter.shiftPerPoint(label) * fontSize)
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

/// Measures where a key label's ink actually sits, so `KeypadLayout.opticalCenterShift`
/// can pull it onto the centre of the disc.
///
/// Measured, not tabulated, for two reasons: the numbers would otherwise be a wall of
/// Playfair-specific constants that go silently wrong the day the font changes, and the
/// backspace glyph "⌫" (U+232B) is NOT in Playfair Display at all — iOS substitutes it
/// from a fallback face, whose metrics no hand-written table could know. CoreText sees
/// the substitution; a table cannot.
@MainActor
private enum OpticalCenter {
    // The shift is linear in point size, so each label is measured once at a reference
    // size and stored per-point. Eleven distinct labels, so the cache stays tiny.
    // ponytail: a plain dictionary — every caller is a SwiftUI body on the main actor.
    private static var cache: [String: CGFloat] = [:]

    /// Shift per point of font size. Positive = down.
    static func shiftPerPoint(_ label: String) -> CGFloat {
        if let hit = cache[label] { return hit }
        let measured = measure(label)
        cache[label] = measured
        return measured
    }

    // CTLineGetImageBounds with a nil context returns CGRectNull — which made every
    // measurement fail the ink.height guard and silently disabled the centring. A 1×1
    // throwaway bitmap context satisfies it; the rect is computed from font tables, so
    // the context's size is irrelevant.
    private static let inkContext = CGContext(
        data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )

    private static func measure(_ label: String) -> CGFloat {
        let reference: CGFloat = 100
        // No Playfair (font failed to register) → 0, i.e. exactly today's centring.
        guard let font = UIFont(name: BloomFontRole.numberFamily, size: reference),
              let context = inkContext else { return 0 }
        let line = CTLineCreateWithAttributedString(
            NSAttributedString(string: label, attributes: [.font: font])
        )
        // Ink bounds, measured from the baseline. Empty for whitespace-only labels.
        let ink = CTLineGetImageBounds(line, context)
        guard !ink.isNull, ink.height > 0 else { return 0 }
        // Line metrics come from Playfair even where a glyph was substituted — that is
        // correct: SwiftUI sizes the line box from the specified font either way.
        return KeypadLayout.opticalCenterShift(
            inkCenter: ink.midY,
            ascender: font.ascender,
            descender: font.descender
        ) / reference
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
    /// gets the hand-drawn glass replica below.
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
            self.bloomGlassReplicaFace(tint: tint, cornerRadius: cornerRadius)
        }
        #else
        self.bloomGlassReplicaFace(tint: tint, cornerRadius: cornerRadius)
        #endif
    }

    /// The pre-26 fallback: hand-drawn glass that replicates the Liquid Glass look —
    /// translucent tint, a top sheen, and a specular hairline border. All gradients,
    /// no Material: the keys sit on a flat themed background, so a live backdrop blur
    /// (×20 keys) would buy nothing and cost real GPU on older phones.
    func bloomGlassReplicaFace(tint: Color, cornerRadius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return background {
            ZStack {
                shape.fill(tint.opacity(0.85))
                shape.fill(LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.32), location: 0),
                        .init(color: .white.opacity(0.06), location: 0.45),
                        .init(color: .clear, location: 0.55),
                        .init(color: .white.opacity(0.1), location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom
                ))
                shape.strokeBorder(LinearGradient(
                    colors: [.white.opacity(0.55), .white.opacity(0.06)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ), lineWidth: 1)
            }
            .compositingGroup()
            // Outside the shape fills, so no clip — a clipShape here would shear it off.
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
        }
    }
}
