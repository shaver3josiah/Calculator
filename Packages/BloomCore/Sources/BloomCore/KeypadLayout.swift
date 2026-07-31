// Foundation, not CoreGraphics: CI runs `swift test` for this package in a Linux
// container, where CGFloat comes from Foundation and CoreGraphics does not exist.
import Foundation

/// Sizing math for the portrait calculator keypad. Pure, so the "keys never clip and
/// never drop under 44pt" guarantees can be tested instead of eyeballed in a simulator.
///
/// Circle keys are a `keyHeight`-diameter disc, so keyHeight IS the visible key size —
/// which is why it is bounded by the cell WIDTH as well as the vertical residual. The
/// old flat 72pt cap ignored width entirely, so a 6.9" phone and an iPad drew the same
/// keys as a 6.1" one and just banked the extra room as dead air.
public enum KeypadLayout {
    public static let columns: CGFloat = 4
    public static let rows: CGFloat = 5
    public static let gap: CGFloat = 10
    /// Cluster cap: keeps keys from becoming ~160pt slabs on iPad.
    public static let maxWidth: CGFloat = 460
    /// Apple's minimum tap target.
    public static let minKey: CGFloat = 44
    /// Shortest the display card is ever allowed to get.
    public static let cardFloor: CGFloat = 128
    /// Slop between the card floor and the keypad so rounding can never overlap them.
    public static let cardSlop: CGFloat = 22

    /// Width of one grid cell when the keypad is laid out in `width` points.
    public static func cellWidth(width: CGFloat) -> CGFloat {
        (min(width, maxWidth) - gap * (columns - 1)) / columns
    }

    /// Total height the keypad grid occupies: `rows` keys plus the gaps between them.
    public static func keypadBlock(keyHeight: CGFloat) -> CGFloat {
        keyHeight * rows + gap * (rows - 1)
    }

    /// Key height (and, in circle mode, the disc diameter).
    ///
    /// - `slack`: the calc slot height minus fixed chrome (memory bar + inter-element gaps).
    /// - `width`: the width available to the keypad.
    ///
    /// Bounded by the vertical residual so the display card keeps its floor, and by the
    /// cell width so a circle can never be wider than its own cell. Floored at 44.
    public static func keyHeight(slack: CGFloat, width: CGFloat) -> CGFloat {
        let vertical = (slack - (cardFloor + cardSlop + gap * (rows - 1))) / rows
        // minKey applied LAST: on a slot too short (or too narrow) to honour both, a
        // reachable key beats a tidy card — the card scrolls its digits, a 40pt key
        // just gets missed.
        return max(minKey, min(cellWidth(width: width), vertical))
    }

    /// Label point size for a key of the given height. Apple's Calculator sets its glyphs
    /// at roughly 40% of the key; the old flat 22pt read as a speck once keys passed 60pt.
    /// Floor 22 keeps small-phone keys exactly as they render today; the cap stops "+/−"
    /// from overflowing its disc on iPad.
    // ponytail: one ratio for every key. Per-label ratios only if a longer glyph ever
    // needs its own; minimumScaleFactor on the Text already absorbs the edge cases.
    public static func labelFont(keyHeight: CGFloat) -> CGFloat {
        min(38, max(22, keyHeight * 0.42))
    }

    /// How far to shift a key label so its INK sits on the centre of the disc.
    /// Positive = down. All arguments in the same unit (points, or em for a 1pt font);
    /// `descender` is negative, matching the UIFont/CoreText convention.
    ///
    /// SwiftUI centres a Text by its LINE BOX (ascender→descender), not by the ink the
    /// glyph actually paints. For this keypad that is the wrong centre twice over:
    ///
    ///  1. Playfair Display's ascender is 1.082 em — sized to clear its tall diacritics —
    ///     against a 0.251 em descender, so the line-box centre lands 0.4155 em above the
    ///     baseline. No glyph's ink centre gets near that, so every label draws low.
    ///  2. Playfair ships OLD-STYLE figures. Measured off the pinned
    ///     `PlayfairDisplay[wght].ttf`: 0/1/2 sit at x-height (ink centre ≈0.26 em),
    ///     3/4/5/7/9 hang ~0.15 em BELOW the baseline (≈0.19 em), and 6/8 rise to cap
    ///     height (≈0.354 em). That 0.169 em spread is ~4.9pt at a 29pt label — the
    ///     digits visibly bounce from key to key.
    ///
    /// Old-style figures are the point of the font in running text (the result display,
    /// history), where a shared baseline makes the rhythm read as intended. A keypad has
    /// no shared baseline — each glyph is alone in its own disc — so each is centred on
    /// its own ink instead. This is deliberately NOT applied to `bloomNumber` globally.
    public static func opticalCenterShift(inkCenter: CGFloat,
                                          ascender: CGFloat,
                                          descender: CGFloat) -> CGFloat {
        inkCenter - (ascender + descender) / 2
    }
}
