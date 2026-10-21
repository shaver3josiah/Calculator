import XCTest
@testable import BloomCore

/// The chained-operator path used to skip the isFinite guard `equals` has, so a
/// divide by zero mid-chain wrote "NaN" into the buffer and every later operand
/// parsed it back out. These pin the recovery.
final class CalcEngineTests: XCTestCase {
    private func press(_ engine: inout CalcEngine, _ digits: String) {
        for ch in digits { engine.digit(ch) }
    }

    func testChainedDivideByZeroDoesNotPoisonTheBuffer() {
        var engine = CalcEngine()
        press(&engine, "5")
        engine.setOp(.divide)
        press(&engine, "0")
        engine.setOp(.add)   // chained: this is where NaN used to land

        XCTAssertFalse(engine.displayText.contains("NaN"), "buffer must never hold NaN, got \(engine.displayText)")
        XCTAssertEqual(engine.displayText, "0", "a non-finite intermediate resets to 0, as equals() does")

        // And the chain still works afterwards rather than staying stuck.
        press(&engine, "7")
        let result = engine.equals()
        XCTAssertEqual(result?.display, "7", "0 + 7 = 7 — the calculator recovered without AC")
    }

    func testEqualsStillReportsErrorOnDivideByZero() {
        var engine = CalcEngine()
        press(&engine, "5")
        engine.setOp(.divide)
        press(&engine, "0")
        XCTAssertEqual(engine.equals()?.display, "Error", "unchanged: equals still surfaces Error")
    }

    func testOrdinaryChainIsUnchanged() {
        var engine = CalcEngine()
        press(&engine, "2")
        engine.setOp(.add)
        press(&engine, "3")
        engine.setOp(.multiply)   // chained: 2+3 = 5 folds in
        XCTAssertEqual(engine.displayText, "5")
        press(&engine, "4")
        XCTAssertEqual(engine.equals()?.display, "20")
    }

    // MARK: Backspace deletes one thing at a time, in every state

    func testBackspaceWhileTypingDropsOneCharacter() {
        var engine = CalcEngine()
        press(&engine, "123")
        XCTAssertTrue(engine.backspace())
        XCTAssertEqual(engine.displayText, "12")
        engine.backspace()
        engine.backspace()
        XCTAssertEqual(engine.displayText, "0")
        XCTAssertFalse(engine.backspace(), "nothing left to delete")
    }

    func testBackspaceAfterOperatorCancelsItAndReopensTheNumber() {
        var engine = CalcEngine()
        press(&engine, "12")
        engine.setOp(.add)
        XCTAssertEqual(engine.expressionText, "12 +")
        XCTAssertTrue(engine.backspace())
        XCTAssertNil(engine.pendingOp, "the operator is gone")
        XCTAssertEqual(engine.expressionText, "")
        XCTAssertEqual(engine.displayText, "12")
        engine.backspace()
        XCTAssertEqual(engine.displayText, "1", "the operand is editable again, not overwritten")
        press(&engine, "5")
        XCTAssertEqual(engine.displayText, "15")
    }

    func testBackspaceAfterChainedOperatorKeepsTheRunningTotal() {
        var engine = CalcEngine()
        press(&engine, "2")
        engine.setOp(.add)
        press(&engine, "3")
        engine.setOp(.multiply)   // running total 5
        engine.backspace()
        XCTAssertNil(engine.pendingOp)
        XCTAssertEqual(engine.displayText, "5")
        XCTAssertNil(engine.equals(), "no operator left to apply")
    }

    func testBackspaceOnResultEditsIt() {
        var engine = CalcEngine()
        press(&engine, "12")
        engine.setOp(.multiply)
        press(&engine, "12")
        _ = engine.equals()
        XCTAssertEqual(engine.displayText, "144")
        XCTAssertTrue(engine.backspace())
        XCTAssertEqual(engine.displayText, "14")
        press(&engine, "0")
        XCTAssertEqual(engine.displayText, "140", "typing continues the edited result")
    }

    func testBackspaceAfterClearAllIsANoOp() {
        var engine = CalcEngine()
        press(&engine, "9")
        engine.setOp(.subtract)
        press(&engine, "4")
        engine.clearAll()
        XCTAssertFalse(engine.backspace())
        XCTAssertEqual(engine.displayText, "0")
        XCTAssertEqual(engine.expressionText, "")
    }
}
