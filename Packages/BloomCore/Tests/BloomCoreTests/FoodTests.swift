import XCTest
@testable import BloomCore

final class FoodTests: XCTestCase {
    func testFoodCount() {
        let foods = FoodLibrary.load()
        XCTAssertEqual(foods.count, 410)
    }

    func testMatchFlour() {
        let match = FoodLibrary.match("flour")
        XCTAssertNotNil(match)
    }

    func testGroupsNonEmpty() {
        let groups = FoodLibrary.groups()
        XCTAssertFalse(groups.isEmpty)
    }
}
