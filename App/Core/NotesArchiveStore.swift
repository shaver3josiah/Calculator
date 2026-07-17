import SwiftUI
import BloomCore

// Her notebook. The live page she's typing lives in DraftStore.notes (so a tab
// switch never costs a word); THIS holds the notes she's chosen to keep — some
// active, some tucked into the archive. Rich text is stored as RTF Data so bold,
// italics, headings and fonts all survive; `plain` is the plain-text mirror kept
// for search, sharing, and turning a note into a list.

struct ArchivedNote: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var plain: String
    var rtf: Data?
    var savedAt: Date = Date()
    var archived: Bool = false

    var displayTitle: String {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { return t }
        // Fall back to the first non-empty line of the body.
        let firstLine = plain.split(whereSeparator: \.isNewline)
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return firstLine.map(String.init) ?? "Untitled note"
    }

    /// Plain text she can drop into a message: title, a blank line, then the words.
    var shareText: String {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let head = t.isEmpty ? "" : t + "\n\n"
        return head + plain.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@Observable
final class NotesArchiveStore {
    private(set) var notes: [ArchivedNote] = []

    /// Active notes (not archived), newest first.
    var active: [ArchivedNote] { notes.filter { !$0.archived }.sorted { $0.savedAt > $1.savedAt } }
    /// The archive, newest first.
    var archivedNotes: [ArchivedNote] { notes.filter { $0.archived }.sorted { $0.savedAt > $1.savedAt } }

    init() {
        notes = JSONStore.shared.get(.notesArchive, as: [ArchivedNote].self) ?? []
    }

    /// Insert or update by id, stamping the save time so it sorts to the top.
    /// An empty note (no title, no words) is never stored — swiping up on a blank
    /// page shouldn't litter her notebook.
    @discardableResult
    func save(_ note: ArchivedNote) -> ArchivedNote? {
        var n = note
        n.savedAt = Date()
        let hasContent = !n.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !n.plain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        guard hasContent else {
            // If this was an existing saved note she cleared to nothing, drop it.
            if let idx = notes.firstIndex(where: { $0.id == n.id }) {
                notes.remove(at: idx); persist()
            }
            return nil
        }
        if let idx = notes.firstIndex(where: { $0.id == n.id }) {
            notes[idx] = n
        } else {
            notes.append(n)
        }
        persist()
        return n
    }

    func setArchived(_ id: UUID, _ archived: Bool) {
        guard let idx = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[idx].archived = archived
        persist()
    }

    /// Copy a note as a brand-new active note, returned so the editor can open it.
    func duplicate(_ note: ArchivedNote) -> ArchivedNote {
        var copy = note
        copy.id = UUID()
        copy.title = note.title.isEmpty ? "" : note.title + " copy"
        copy.archived = false
        copy.savedAt = Date()
        notes.append(copy)
        persist()
        return copy
    }

    func delete(_ id: UUID) {
        notes.removeAll { $0.id == id }
        persist()
    }

    func note(id: UUID?) -> ArchivedNote? {
        guard let id else { return nil }
        return notes.first { $0.id == id }
    }

    private func persist() {
        JSONStore.shared.set(.notesArchive, notes)
    }
}
