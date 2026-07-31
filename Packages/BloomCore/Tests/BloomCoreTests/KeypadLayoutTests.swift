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
}
