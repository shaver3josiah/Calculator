import XCTest
@testable import BloomCore

/// The calculator now renders every settled result through `fmt(_:decimals:)`, so this
/// pins the contract the display depends on: her precision, but the same grouping,
/// stripping and exponential thresholds the 8-place formatter always had.
final class FormatterDecimalsTests: XCTestCase {
    func testRoundsToRequestedPlaces() {
        XCTAssertEqual(Formatters.fmt(1234.5678, decimals: 0), "1,235")
        XCTAssertEqual(Formatters.fmt(1234.5678, decimals: 1), "1,234.6")
        XCTAssertEqual(Formatters.fmt(1234.5678, decimals: 3), "1,234.568")
        XCTAssertEqual(Formatters.fmt(1234.5678, decimals: 8), "1,234.5678")
    }

    /// Half-up (JS Math.round), not printf's half-to-even: 2.5 at 0 places is 3, not 2.
    func testHalfUpAtEachPrecision() {
        XCTAssertEqual(Formatters.fmt(2.5, decimals: 0), "3")
        XCTAssertEqual(Formatters.fmt(0.5, decimals: 0), "1")
        XCTAssertEqual(Formatters.fmt(0.25, decimals: 1), "0.3")
        XCTAssertEqual(Formatters.fmt(1.2345, decimals: 3), "1.235")
        XCTAssertEqual(Formatters.fmt(1.0 / 3.0, decimals: 8), "0.33333333")
    }

    /// 2+2 must stay "4" — never "4.000".
    func testStripsTrailingZeros() {
        XCTAssertEqual(Formatters.fmt(4.0, decimals: 3), "4")
        XCTAssertEqual(Formatters.fmt(4.0, decimals: 8), "4")
        XCTAssertEqual(Formatters.fmt(4.5, decimals: 3), "4.5")
        XCTAssertEqual(Formatters.fmt(0.1, decimals: 3), "0.1")
    }

    func testGroupsIntegerPart() {
        XCTAssertEqual(Formatters.fmt(1000000.5, decimals: 0), "1,000,001")
        XCTAssertEqual(Formatters.fmt(-1234.5678, decimals: 2), "-1,234.57")
        XCTAssertEqual(Formatters.fmt(999.5, decimals: 0), "1,000")
    }

    func testExponentialThresholdsUnchangedByDecimals() {
        XCTAssertEqual(Formatters.fmt(1e15, decimals: 3), Formatters.fmt(1e15))
        XCTAssertEqual(Formatters.fmt(1e-7, decimals: 3), Formatters.fmt(1e-7))
        XCTAssertEqual(Formatters.fmt(1e-7, decimals: 0), "1.0000e-7")
        // Just inside the thresholds: still the plain grouped form.
        XCTAssertEqual(Formatters.fmt(1e-6, decimals: 8), "0.000001")
    }

    func testErrorAndZero() {
        XCTAssertEqual(Formatters.fmt(Double.nan, decimals: 3), "Error")
        XCTAssertEqual(Formatters.fmt(Double.infinity, decimals: 3), "Error")
        XCTAssertEqual(Formatters.fmt(-Double.infinity, decimals: 0), "Error")
        XCTAssertEqual(Formatters.fmt(0, decimals: 3), "0")
        // Rounds away to nothing rather than showing a bare "-0".
        XCTAssertEqual(Formatters.fmt(-0.0001, decimals: 2), "0")
    }

    func testDecimalsClamped() {
        XCTAssertEqual(Formatters.fmt(1234.5678, decimals: -3), Formatters.fmt(1234.5678, decimals: 0))
        XCTAssertEqual(Formatters.fmt(1234.5678, decimals: 99), Formatters.fmt(1234.5678, decimals: 8))
        XCTAssertEqual(Formatters.plain(1.23456789, decimals: -1), Formatters.plain(1.23456789, decimals: 0))
        XCTAssertEqual(Formatters.plain(1.23456789, decimals: 99), Formatters.plain(1.23456789, decimals: 8))
    }

    /// The no-decimals entry points must keep behaving exactly as they did at 8 places —
    /// CalcEngine, recipes and the converters all still call them.
    func testDefaultOverloadsUnchanged() {
        for n in [0.0, 4.0, 1234.5678, -1234.5678, 1e15, 1e-7, 1.0 / 3.0, 1000000.5] {
            XCTAssertEqual(Formatters.fmt(n), Formatters.fmt(n, decimals: 8), "fmt(\(n))")
            XCTAssertEqual(Formatters.plain(n), Formatters.plain(n, decimals: 8), "plain(\(n))")
        }
    }

    /// plain() is the engine's buffer format: rounded, stripped, but never grouped —
    /// CalcStore parses it straight back through Double().
    func testPlainRoundsWithoutGrouping() {
        XCTAssertEqual(Formatters.plain(1234.5678, decimals: 3), "1234.568")
        XCTAssertEqual(Formatters.plain(1000000.5, decimals: 0), "1000001")
        XCTAssertEqual(Formatters.plain(4.0, decimals: 3), "4")
        XCTAssertNotNil(Double(Formatters.plain(1234.5678, decimals: 3)))
    }
}
