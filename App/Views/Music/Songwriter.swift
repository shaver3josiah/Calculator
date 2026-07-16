import SwiftUI
import Foundation

// MARK: - Model

/// The shape of a song. These are the structure options she picks from when a
/// block becomes a verse, a chorus, a bridge (or the little intro/outro pieces).
enum SongSectionKind: String, Codable, CaseIterable, Identifiable {
    case intro, verse, prechorus, chorus, bridge, outro

    var id: String { rawValue }

    var label: String {
        switch self {
        case .intro: return "Intro"
        case .verse: return "Verse"
        case .prechorus: return "Pre-chorus"
        case .chorus: return "Chorus"
        case .bridge: return "Bridge"
        case .outro: return "Outro"
        }
    }

    /// Theme token for the section's color dot — the whole song is readable at
    /// a glance by shape and color, the way a lead sheet is. Every value clears
    /// 3:1 on the soft/white fills these dots sit on (the pale gold
    /// flowerCenter did not), and no two kinds share a color.
    var token: String {
        switch self {
        case .intro:     return "muted"
        case .verse:     return "primary"
        case .prechorus: return "good"
        case .chorus:    return "primaryStrong"
        case .bridge:    return "deep"
        case .outro:     return "text"
        }
    }

    var symbol: String {
        switch self {
        case .intro:     return "arrow.right.to.line"
        case .verse:     return "text.alignleft"
        case .prechorus: return "arrow.up.right"
        case .chorus:    return "star.fill"
        case .bridge:    return "arrow.triangle.branch"
        case .outro:     return "arrow.left.to.line"
        }
    }

    /// The three she reaches for most get one-tap buttons; the rest live in a menu.
    static let headline: [SongSectionKind] = [.verse, .chorus, .bridge]
    static let extras: [SongSectionKind] = [.intro, .prechorus, .outro]
}

struct SongSection: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var kind: SongSectionKind = .verse
    var chords: String = ""
    var lyrics: String = ""

    var isEmpty: Bool {
        chords.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && lyrics.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(id: UUID = UUID(), kind: SongSectionKind = .verse, chords: String = "", lyrics: String = "") {
        self.id = id
        self.kind = kind
        self.chords = chords
        self.lyrics = lyrics
    }

    /// Lenient decode: a missing key falls back to its default instead of
    /// failing the whole songbook. Synthesized Codable does NOT do this, so
    /// adding one field later would otherwise make every saved song
    /// unreadable. (Same guard SoundStore uses for its prefs blob.)
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        kind = (try? c.decode(SongSectionKind.self, forKey: .kind)) ?? .verse
        chords = (try? c.decode(String.self, forKey: .chords)) ?? ""
        lyrics = (try? c.decode(String.self, forKey: .lyrics)) ?? ""
    }
}

struct Song: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String = ""
    var sections: [SongSection] = [SongSection(kind: .verse), SongSection(kind: .chorus)]
    var updatedAt: Date = Date()

    init(id: UUID = UUID(), title: String = "",
         sections: [SongSection] = [SongSection(kind: .verse), SongSection(kind: .chorus)],
         updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.sections = sections
        self.updatedAt = updatedAt
    }

    /// Lenient decode — see SongSection.init(from:). Her words outlive schema changes.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        title = (try? c.decode(String.self, forKey: .title)) ?? ""
        sections = (try? c.decode([SongSection].self, forKey: .sections)) ?? []
        updatedAt = (try? c.decode(Date.self, forKey: .updatedAt)) ?? Date()
    }

    var displayTitle: String {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "Untitled song" : t
    }

    /// Numbered labels: repeated kinds count up ("Verse 1", "Verse 2"), a lone
    /// one stays bare ("Bridge") — exactly how a real lead sheet reads.
    func label(for section: SongSection) -> String {
        let sameKind = sections.filter { $0.kind == section.kind }
        guard sameKind.count > 1,
              let n = sameKind.firstIndex(where: { $0.id == section.id }) else {
            return section.kind.label
        }
        return "\(section.kind.label) \(n + 1)"
    }

    /// The whole song as plain text — chords over lyrics, ready to share or print.
    var shareText: String {
        var out = [displayTitle, ""]
        for s in sections where !s.isEmpty {
            out.append("[\(label(for: s))]")
            let chords = s.chords.trimmingCharacters(in: .whitespacesAndNewlines)
            if !chords.isEmpty { out.append(chords) }
            let lyrics = s.lyrics.trimmingCharacters(in: .whitespacesAndNewlines)
            if !lyrics.isEmpty { out.append(lyrics) }
            out.append("")
        }
        out.append("Written in Hannah's Calculator 🌸")
        return out.joined(separator: "\n")
    }

    /// Every chord in the song, in playing order.
    var allVoices: [ChordVoice] {
        sections.flatMap { ChordParser.parseText($0.chords) }
    }
}

// MARK: - Store

/// Her songbook. Persisted as one JSON file beside the key-chords blob — the
/// same shape as MusicStore's persistence, kept deliberately separate so a
/// songwriting mistake can never touch her chord settings.
@Observable
final class SongBook {
    private(set) var songs: [Song] = []

    private static let fileName = "bloom_songs"

    init() {
        songs = Self.load()
    }

    /// Insert or update, newest first. A brand-new blank song is not stored —
    /// opening the songwriter and closing it again must not litter her book —
    /// but a song ALREADY in the book is never removed here, however empty she
    /// leaves it. (Clearing a title to retype it must not delete the song; only
    /// an explicit Delete does that.)
    func upsert(_ song: Song) {
        var s = song
        s.updatedAt = Date()
        let hasContent = !s.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || s.sections.contains { !$0.isEmpty }
        let alreadySaved = songs.contains { $0.id == s.id }
        guard hasContent || alreadySaved else { return }
        if let idx = songs.firstIndex(where: { $0.id == s.id }) {
            songs[idx] = s
        } else {
            songs.append(s)
        }
        songs.sort { $0.updatedAt > $1.updatedAt }
        persist()
    }

    func delete(_ id: UUID) {
        songs.removeAll { $0.id == id }
        persist()
    }

    /// The song the songwriter opens with: her most recent, or a fresh page.
    func mostRecentOrNew() -> Song {
        songs.first ?? Song()
    }

    // MARK: persistence

    private static func fileURL() -> URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fm.temporaryDirectory
        let dir = base.appendingPathComponent("Bloom", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(fileName).appendingPathExtension("json")
    }

    /// Read the book. If the file exists but can't be read, the bytes are
    /// QUARANTINED (renamed aside) rather than left in place to be overwritten
    /// by the next autosave — a song she spent an evening on is never silently
    /// replaced by an empty file, and the original is still on disk to recover.
    private static func load() -> [Song] {
        let url = fileURL()
        guard let data = try? Data(contentsOf: url) else { return [] }   // no file yet: fine
        if let decoded = try? JSONDecoder().decode([Song].self, from: data) {
            return decoded.sorted { $0.updatedAt > $1.updatedAt }
        }
        let stamp = Int(Date().timeIntervalSince1970)
        let quarantine = url.deletingPathExtension()
            .appendingPathExtension("corrupt-\(stamp).json")
        try? FileManager.default.moveItem(at: url, to: quarantine)
        ToastCenter.shared.show(title: "Couldn't read your songbook",
                                message: "A copy was kept safe. Nothing was overwritten.")
        return []
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(songs) else { return }
        do {
            try data.write(to: Self.fileURL(), options: .atomic)
        } catch {
            // She should never keep typing into a page that stopped saving.
            ToastCenter.shared.show(title: "Couldn't save just now",
                                    message: "Your song is still on screen — try sharing it out.")
        }
    }
}
