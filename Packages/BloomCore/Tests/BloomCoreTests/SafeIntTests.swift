import XCTest
@testable import BloomCore

/// These guards exist to stop a hard crash, so the poison inputs get the test.
final class SafeIntTests: XCTestCase {
    func testPoisonInputsClampInsteadOfTrapping() {
        // The exact string that bricked the Projection tab: > Int64.max.
        XCTAssertEqual("9999999999999999999".clampedInt(to: 0...100, fallback: 20), 100)
        XCTAssertEqual("1e30".clampedInt(to: 0...100, fallback: 20), 100)
        XCTAssertEqual("-1e30".clampedInt(to: 0...100, fallback: 20), 0)
        // NaN/infinity cannot be clamped meaningfully, so they take the fallback.
        XCTAssertEqual("nan".clampedInt(to: 0...100, fallback: 20), 20)
        XCTAssertEqual("inf".clampedInt(to: 0...100, fallback: 20), 20)
        XCTAssertEqual("-inf".clampedInt(to: 0...100, fallback: 20), 20)
        // Unparseable and empty take the fallback too.
        XCTAssertEqual("".clampedInt(to: 0...100, fallback: 20), 20)
        XCTAssertEqual("abc".clampedInt(to: 0...100, fallback: 20), 20)
    }

    func testOrdinaryInputsAreUnchanged() {
        XCTAssertEqual("20".clampedInt(to: 0...100, fallback: 5), 20)
        XCTAssertEqual("0".clampedInt(to: 0...100, fallback: 5), 0)
        XCTAssertEqual("7.9".clampedInt(to: 0...100, fallback: 5), 7, "truncates like Int(Double) always did")
        XCTAssertEqual((42.0).clampedInt(to: 0...100, fallback: 5), 42)
        XCTAssertEqual(Double.greatestFiniteMagnitude.clampedInt(to: 0...16, fallback: 0), 16)
    }
}
