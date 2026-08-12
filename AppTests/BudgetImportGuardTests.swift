import XCTest
import BloomCore
@testable import Bloom

/// The import confirm fires off `replacementSummary` being non-nil, so that one
/// method decides both "is this destructive?" and what the warning says. If it
/// ever answers wrong, either she gets a dialog for a harmless import (and
/// learns to tap through) or a month disappears with no warning at all.
@MainActor
final class BudgetImportGuardTests: XCTestCase {
    private func freshStore() -> BudgetStore {
        JSONStore.shared.remove(.budget2)
        return BudgetStore()
    }

    override func tearDown() {
        JSONStore.shared.remove(.budget2)
        super.tearDown()
    }

    func testMonthSheHasIsReportedAsDestructive() {
        let store = freshStore()
        let current = store.db.cur

        let summary = store.replacementSummary(for: current)

        XCTAssertNotNil(summary, "the month she is looking at has content to lose")
        XCTAssertTrue(summary!.contains("categor"), "warning names the categories: \(summary!)")
        XCTAssertTrue(summary!.contains("$"), "warning names the money: \(summary!)")
    }

    func testMonthSheDoesNotHaveIsNotDestructive() {
        let store = freshStore()
        XCTAssertNil(
            store.replacementSummary(for: "1999-01"),
            "a month with no budget of her own must import with no dialog"
        )
    }

    func testPreviewDoesNotCommitAnything() {
        let store = freshStore()
        let shared = store.exportText()
        let before = store.db

        let preview = store.previewImport(shared)

        XCTAssertNotNil(preview, "its own export must be readable back")
        XCTAssertEqual(preview?.key, store.db.cur)
        XCTAssertEqual(store.db, before, "previewing must not touch her data")
    }

    func testPreviewRejectsJunk() {
        let store = freshStore()
        XCTAssertNil(store.previewImport("just some text she pasted"))
        XCTAssertNil(store.previewImport(""))
    }

    /// Round trip: the summary the dialog shows for the incoming budget must
    /// match what that budget actually becomes once imported.
    func testIncomingSummaryMatchesWhatLands() {
        let store = freshStore()
        let shared = store.exportText()
        guard let preview = store.previewImport(shared) else {
            return XCTFail("export should preview")
        }

        XCTAssertTrue(store.importShared(shared))

        XCTAssertEqual(
            store.replacementSummary(for: preview.key),
            preview.summary,
            "what the dialog promised is what arrived"
        )
    }
}
