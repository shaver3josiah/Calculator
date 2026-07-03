import XCTest
@testable import BloomCore

final class EggContentTests: XCTestCase {
    func testAllEggsLoad() {
        let eggs = EasterEggs.all()
        XCTAssertEqual(eggs.count, 10)
    }

    func testEveryEggHasNonEmptyLinesAndTriggers() {
        let eggs = EasterEggs.all()
        for egg in eggs {
            XCTAssertFalse(egg.lines.isEmpty, egg.id)
            XCTAssertFalse(egg.triggers.isEmpty, egg.id)
            for line in egg.lines {
                XCTAssertFalse(line.isEmpty, egg.id)
            }
            for trigger in egg.triggers {
                XCTAssertFalse(trigger.isEmpty, egg.id)
            }
        }
    }

    func testRomansEggHasVerseTwentySix() {
        let eggs = EasterEggs.all()
        guard let romans = eggs.first(where: { $0.id == "no-condemnation" }) else {
            XCTFail("romans egg (no-condemnation) not found")
            return
        }
        guard let more = romans.more else {
            XCTFail("romans egg has no more array")
            return
        }
        let containsTwentySix = more.contains { $0.contains("26") }
        XCTAssertTrue(containsTwentySix, "romans egg more array should contain a line with 26")
    }
}
