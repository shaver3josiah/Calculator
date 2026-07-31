import XCTest
@testable import BloomCore

/// The keypad's whole job is to fill the screen without clipping the display card and
/// without dropping under Apple's 44pt tap target. Both bounds are arithmetic, so they
/// get asserted here instead of eyeballed in a simulator.
final class KeypadLayoutTests: XCTestCase {
    // CalcView applies .padding(.horizontal, 16), so keypad width = screen width - 32.
    private let seWidth: CGFloat = 375 - 32          // iPhone SE
    private let proWidth: CGFloat = 402 - 32         // iPhone 16/17 Pro
    private let proMaxWidth: CGFloat = 440 - 32      // iPhone 16/17 Pro Max
    private let padWidth: CGFloat = 834 - 32         // iPad 11"

    // MARK: - No clipping

    /// The load-bearing invariant: whenever the keys are not pinned to the 44pt floor,
    /// the keypad plus the display card's floor must fit inside the available slack.
    /// Sweeps every plausible slot height on every supported width.
    func testKeypadPlusCardFloorNeverExceedsSlack() {
        for width in [seWidth, proWidth, proMaxWidth, padWidth] {
            for slack in stride(from: CGFloat(300), through: 1200, by: 1) {
                let h = KeypadLayout.keyHeight(slack: slack, width: width)
                guard h > KeypadLayout.minKey else { continue }   // floor deliberately wins on tiny slots
                let used = KeypadLayout.keypadBlock(keyHeight: h) + KeypadLayout.cardFloor
                XCTAssertLessThanOrEqual(used, slack, "clipped at width \(width), slack \(slack)")
            }
        }
    }

    /// A circle key is a keyHeight-diameter disc, so keyHeight may never exceed the cell
    /// it sits in or neighbouring discs would overlap.
    func testKeyNeverWiderThanItsCell() {
        for width in [seWidth, proWidth, proMaxWidth, padWidth] {
            for slack in stride(from: CGFloat(300), through: 1200, by: 1) {
                let h = KeypadLayout.keyHeight(slack: slack, width: width)
                XCTAssertLessThanOrEqual(h, KeypadLayout.cellWidth(width: width))
            }
        }
    }

    func testKeyNeverBelowTapTarget() {
        for width in [seWidth, proWidth, proMaxWidth, padWidth] {
            for slack in stride(from: CGFloat(0), through: 1200, by: 1) {
                XCTAssertGreaterThanOrEqual(
                    KeypadLayout.keyHeight(slack: slack, width: width),
                    KeypadLayout.minKey
                )
            }
        }
    }

    // MARK: - Actually scales with the screen

    /// The bug being fixed: a flat 72pt cap meant a Pro Max drew the same keys as an SE.
    /// Given equal vertical room, a wider phone must now get bigger keys.
    func testWiderPhoneGetsBiggerKeys() {
        let slack: CGFloat = 900   // width-bound, not height-bound
        let se = KeypadLayout.keyHeight(slack: slack, width: seWidth)
        let pro = KeypadLayout.keyHeight(slack: slack, width: proWidth)
        let proMax = KeypadLayout.keyHeight(slack: slack, width: proMaxWidth)
        XCTAssertGreaterThan(pro, se)
        XCTAssertGreaterThan(proMax, pro)
        XCTAssertGreaterThan(proMax, 72, "the old flat cap must no longer bind")
    }

    /// The 460pt cluster cap still holds on iPad so keys don't become slabs.
    func testTabletClampsToClusterWidth() {
        let h = KeypadLayout.keyHeight(slack: 1200, width: padWidth)
        XCTAssertEqual(h, KeypadLayout.cellWidth(width: KeypadLayout.maxWidth), accuracy: 0.001)
    }

    // MARK: - Label size

    func testLabelFontScalesWithKeyAndClamps() {
        XCTAssertEqual(KeypadLayout.labelFont(keyHeight: 44), 22, accuracy: 0.001)   // unchanged on SE
        XCTAssertGreaterThan(KeypadLayout.labelFont(keyHeight: 72), 22)              // grows with the key
        XCTAssertEqual(KeypadLayout.labelFont(keyHeight: 200), 38, accuracy: 0.001)  // capped
        // Monotonic: a bigger key never gets a smaller glyph.
        var previous = KeypadLayout.labelFont(keyHeight: 44)
        for h in stride(from: CGFloat(44), through: 160, by: 1) {
            let size = KeypadLayout.labelFont(keyHeight: h)
            XCTAssertGreaterThanOrEqual(size, previous)
            previous = size
        }
    }

    /// A glyph must stay comfortably inside its own disc — the label is centred in a
    /// keyHeight-wide circle, so a runaway ratio would push wide labels like "+/−" out.
    func testLabelAlwaysFitsInsideTheDisc() {
        for h in stride(from: KeypadLayout.minKey, through: 160, by: 1) {
            XCTAssertLessThanOrEqual(KeypadLayout.labelFont(keyHeight: h) / h, 0.55)
        }
    }

    // MARK: - Optical centring
    //
    // Fixtures below are MEASURED off the pinned PlayfairDisplay[wght].ttf that
    // scripts/fetch_fonts.sh downloads (google/fonts @ 26c5c976, unitsPerEm 1000),
    // expressed in em. The app supplies the live equivalents via CoreText; these pin
    // the formula's sign and magnitude so a regression can't silently re-introduce the
    // bouncing digits.

    private let ascender: CGFloat = 1.082      // Playfair, sized for its tall diacritics
    private let descender: CGFloat = -0.251
    /// Ink centre above the baseline, per digit. Note the three tiers — this IS the bug:
    /// 0/1/2 x-height, 3/4/5/7/9 descending, 6/8 ascending.
    private let inkCentres: [Character: CGFloat] = [
        "0": 0.2575, "1": 0.2630, "2": 0.2620, "3": 0.1890, "4": 0.1940,
        "5": 0.2085, "6": 0.3545, "7": 0.1855, "8": 0.3540, "9": 0.1905,
        ".": 0.0500
    ]

    private func shift(_ ch: Character) -> CGFloat {
        KeypadLayout.opticalCenterShift(
            inkCenter: inkCentres[ch]!, ascender: ascender, descender: descender
        )
    }

    /// Playfair's line box centres 0.4155 em above the baseline and no glyph's ink
    /// reaches that, so every label is currently drawn LOW and must move up.
    func testEveryLabelCurrentlyDrawsLowAndMovesUp() {
        for ch in inkCentres.keys {
            XCTAssertLessThan(shift(ch), 0, "\(ch) should move up, not down")
        }
    }

    func testCorrectionMatchesMeasuredFont() {
        XCTAssertEqual(shift("7"), -0.2300, accuracy: 0.0005)   // deepest descender
        XCTAssertEqual(shift("6"), -0.0610, accuracy: 0.0005)   // tallest ascender
        XCTAssertEqual(shift("0"), -0.1580, accuracy: 0.0005)   // x-height
        XCTAssertEqual(shift("."), -0.3655, accuracy: 0.0005)   // worst offender overall
    }

    /// The payload: uncorrected, 6 and 7 differ by 0.169 em of ink centre — ~4.9pt at a
    /// 29pt label. Correcting both lands them on the same centre, so the gap goes to zero.
    func testCorrectionFlattensTheDigitSpread() {
        let raw = "0123456789".map { inkCentres[$0]! }
        let spread = raw.max()! - raw.min()!
        XCTAssertEqual(spread, 0.169, accuracy: 0.0005)
        XCTAssertGreaterThan(spread * 28.7, 4.8, "the wobble this fixes, in pt at 29pt")

        // Distance of each digit's ink centre from the disc centre (positive = below)
        // once the correction is applied. Zero for every digit — that IS the fix.
        let boxCenter = (ascender + descender) / 2
        let residual = "0123456789".map { (boxCenter - inkCentres[$0]!) + shift($0) }
        XCTAssertEqual(residual.max()!, 0, accuracy: 1e-9)
        XCTAssertEqual(residual.min()!, 0, accuracy: 1e-9)
    }

    /// Ink already on the line-box centre needs no nudge.
    func testCenteredInkNeedsNoShift() {
        let boxCenter = (ascender + descender) / 2
        XCTAssertEqual(
            KeypadLayout.opticalCenterShift(inkCenter: boxCenter,
                                            ascender: ascender, descender: descender),
            0, accuracy: 1e-12
        )
    }

    /// Linear in point size — the app measures once per label and scales.
    func testShiftScalesLinearlyWithPointSize() {
        for size in [22.0, 28.7, 38.0] as [CGFloat] {
            XCTAssertEqual(
                KeypadLayout.opticalCenterShift(inkCenter: inkCentres["7"]! * size,
                                                ascender: ascender * size,
                                                descender: descender * size),
                shift("7") * size, accuracy: 1e-9
            )
        }
    }
}
