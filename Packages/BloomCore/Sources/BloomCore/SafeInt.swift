import Foundation

// Swift's `Int(_: Double)` is precondition-checked, not failable and not
// clamping: it TRAPS on NaN, on infinity, and on anything outside Int64. Every
// site in this app that reaches for it is converting a number she typed, so
// "she leaned on the 9 key" and "she pasted a card number into the wrong field"
// are both a hard crash — and where the field is a persisted draft, the crash
// replays on every launch and the tab is dead for good.
//
// Clamping is always the right answer here: these values index glyph grids and
// year loops, all of which have a sane ceiling anyway.

public extension Double {
    /// Clamp into `range`, then convert. `fallback` is only for NaN/infinity,
    /// where clamping has no meaning.
    func clampedInt(to range: ClosedRange<Int>, fallback: Int) -> Int {
        guard isFinite else { return fallback }
        return Int(Swift.min(Swift.max(self, Double(range.lowerBound)), Double(range.upperBound)))
    }
}

public extension String {
    /// Free-text field → Int, total for every possible string.
    func clampedInt(to range: ClosedRange<Int>, fallback: Int) -> Int {
        guard let v = Double(self) else { return fallback }
        return v.clampedInt(to: range, fallback: fallback)
    }
}
