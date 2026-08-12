import XCTest
import BloomCore
@testable import Bloom

/// `stash` is the whole fix for "opening a note destroyed the one I was writing",
/// and its blank guard is load-bearing: `save` DELETES a stored note that has
/// been cleared to nothing, so stashing a blank page must not call it.
@MainActor
final class NotesStashTests: XCTestCase {
    private func freshStore() -> NotesArchiveStore {
        // The store loads from the shared JSONStore, so clear the key first and
        // remove anything this test added afterwards.
        JSONStore.shared.remove(.notesArchive)
        return NotesArchiveStore()
    }

    override func tearDown() {
        JSONStore.shared.remove(.notesArchive)
        super.tearDown()
    }

    func testStashKeepsTheLivePage() {
        let store = freshStore()
        let draft = NotesDraft(id: nil, title: "Groceries", body: "milk\neggs", rtf: nil)

        let kept = store.stash(draft)

        XCTAssertNotNil(kept, "a page with words must be kept")
        XCTAssertEqual(store.notes.count, 1)
        XCTAssertEqual(store.notes.first?.title, "Groceries")
        XCTAssertEqual(store.notes.first?.plain, "milk\neggs")
    }

    /// The regression that started all this: open() replaced the draft outright.
    /// Stashing first must leave BOTH notes in the notebook.
    func testStashBeforeOpeningAnotherNoteLosesNothing() {
        let store = freshStore()
        let existing = store.save(ArchivedNote(title: "Recipe", plain: "flour"))
        XCTAssertNotNil(existing)

        // She is midway through a different, never-saved page.
        let live = NotesDraft(id: nil, title: "Packing", body: "passport")
        store.stash(live)

        XCTAssertEqual(store.notes.count, 2, "the live page and the saved note both survive")
        XCTAssertTrue(store.notes.contains { $0.title == "Packing" })
        XCTAssertTrue(store.notes.contains { $0.title == "Recipe" })
    }

    /// The dangerous edge. A blank page carrying the id of a saved note must not
    /// reach `save`, which would delete that note.
    func testStashingABlankPageNeverDeletesTheSavedNote() {
        let store = freshStore()
        guard let saved = store.save(ArchivedNote(title: "Keep me", plain: "words")) else {
            return XCTFail("setup failed")
        }

        // Same id, nothing typed — e.g. she cleared the page then tapped a note.
        let blank = NotesDraft(id: saved.id, title: "   ", body: "\n\n")
        let result = store.stash(blank)

        XCTAssertNil(result, "nothing to keep")
        XCTAssertEqual(store.notes.count, 1, "the saved note must still be there")
        XCTAssertEqual(store.notes.first?.title, "Keep me")
    }

    func testStashUpdatesInPlaceRatherThanDuplicating() {
        let store = freshStore()
        guard let saved = store.save(ArchivedNote(title: "Draft", plain: "one line")) else {
            return XCTFail("setup failed")
        }

        let edited = NotesDraft(id: saved.id, title: "Draft", body: "one line\ntwo lines")
        store.stash(edited)

        XCTAssertEqual(store.notes.count, 1, "same id edits, never duplicates")
        XCTAssertEqual(store.notes.first?.plain, "one line\ntwo lines")
    }

    /// Archived stays archived when the page is stashed again.
    func testStashPreservesArchivedFlag() {
        let store = freshStore()
        var note = ArchivedNote(title: "Old", plain: "text")
        note.archived = true
        guard let saved = store.save(note) else { return XCTFail("setup failed") }

        store.stash(NotesDraft(id: saved.id, title: "Old", body: "text edited"))

        XCTAssertEqual(store.notes.first?.archived, true, "stashing must not un-archive")
    }
}
