import XCTest
@testable import BloomCore

/// The write path is debounced and coalesced, so the three things that would
/// silently lose her data get one check each.
final class PersistenceTests: XCTestCase {
    private func makeStore() -> (JSONStore, URL) {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("bloomstore-\(UUID().uuidString)")
        return (JSONStore(directory: dir), dir)
    }

    private func fileExists(_ dir: URL, _ key: StoreKey) -> Bool {
        FileManager.default.fileExists(
            atPath: dir.appendingPathComponent(key.rawValue).appendingPathExtension("json").path
        )
    }

    /// A value still inside the debounce window must read back as itself, or a
    /// store that saves then reloads sees a stale number.
    func testReadYourWrites() {
        let (store, dir) = makeStore()
        store.set(.memory, 42.5)
        XCTAssertEqual(store.get(.memory, as: Double.self), 42.5, "pending value must win over disk")
        XCTAssertFalse(fileExists(dir, .memory), "write should still be debounced, not on disk yet")
    }

    /// Flush is the app-backgrounding path: after it, the bytes are on disk and
    /// a fresh store (cold launch) finds them.
    func testFlushLandsOnDisk() {
        let (store, dir) = makeStore()
        store.set(.memory, 7.0)
        store.flush()
        XCTAssertTrue(fileExists(dir, .memory), "flush must write through")
        XCTAssertEqual(JSONStore(directory: dir).get(.memory, as: Double.self), 7.0, "cold read")
    }

    /// Only the last value per key may reach disk, and a remove must not be
    /// undone by a write still sitting in the queue.
    func testCoalesceAndRemove() {
        let (store, dir) = makeStore()
        for v in 1...5 { store.set(.memory, Double(v)) }
        store.flush()
        XCTAssertEqual(JSONStore(directory: dir).get(.memory, as: Double.self), 5.0, "last write wins")

        store.set(.memory, 99.0)
        store.remove(.memory)
        store.flush()
        XCTAssertFalse(fileExists(dir, .memory), "remove must drop the queued write too")
        XCTAssertNil(store.get(.memory, as: Double.self))
    }
}
