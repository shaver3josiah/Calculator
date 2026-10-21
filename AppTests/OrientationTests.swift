import XCTest
import UIKit
import BloomCore
@testable import Bloom

/// Rotation went missing once with no code change to blame: the app shipped all
/// four orientations, but a saved Portrait lock pinned it and nothing said so.
/// These pin the three things that have to stay true for it to turn.
@MainActor
final class OrientationTests: XCTestCase {
    override func tearDown() {
        JSONStore.shared.remove(.orientationPref)
        JSONStore.shared.remove(.orientation)
        super.tearDown()
    }

    /// The runtime lock can only narrow what Info.plist allows, never widen it.
    func testInfoPlistAllowsLandscape() {
        let allowed = Bundle.main.object(forInfoDictionaryKey: "UISupportedInterfaceOrientations") as? [String] ?? []
        XCTAssertTrue(allowed.contains("UIInterfaceOrientationPortrait"))
        XCTAssertTrue(allowed.contains("UIInterfaceOrientationLandscapeLeft"))
        XCTAssertTrue(allowed.contains("UIInterfaceOrientationLandscapeRight"))
    }

    func testAutomaticAllowsEveryOrientation() {
        XCTAssertEqual(OrientationPref.auto.mask, .all)
        XCTAssertEqual(OrientationPref.portrait.mask, .portrait)
        XCTAssertEqual(OrientationPref.landscape.mask, .landscape)
    }

    func testFreshInstallRotates() {
        JSONStore.shared.remove(.orientationPref)
        XCTAssertEqual(ThemeStore().orientation, .auto)
    }

    func testV1LockDoesNotSurviveTheReset() {
        JSONStore.shared.set(.orientation, "portrait")
        JSONStore.shared.remove(.orientationPref)
        XCTAssertEqual(ThemeStore().orientation, .auto, "a Portrait pin saved before the reset must not come back")
        XCTAssertNil(JSONStore.shared.get(.orientation, as: String.self), "the retired key is cleaned up")
    }

    func testAChoiceMadeAfterTheResetSticks() {
        JSONStore.shared.set(.orientationPref, "landscape")
        XCTAssertEqual(ThemeStore().orientation, .landscape)
    }
}
