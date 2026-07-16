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
    /// a glance by shape and color, the way a lead sheet is.
    var token: String {
        switch self {
        case .intro:     return "muted"
        case .verse:     return "primary"
        case .prechorus: return "flowerCenter"
        case .chorus:    return "primaryStrong"
        case .bridge:    return "deep"
        case .outro:     return "muted"
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
}

struct Song: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String = ""
    var sections: [SongSection] = [SongSection(kind: .verse), SongSection(kind: .chorus)]
    var updatedAt: Date = Date()

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

    /// Insert or update, newest first. Empty, untitled songs are never stored —
    /// opening the songwriter and closing it again must not litter her book.
    func upsert(_ song: Song) {
        var s = song
        s.updatedAt = Date()
        let worthKeeping = !s.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || s.sections.contains { !$0.isEmpty }
        guard worthKeeping else {
            if let idx = songs.firstIndex(where: { $0.id == s.id }) {
                songs.remove(at: idx)
                persist()
            }
            return
        }
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

    private static func load() -> [Song] {
        guard let data = try? Data(contentsOf: fileURL()),
              let decoded = try? JSONDecoder().decode([Song].self, from: data) else { return [] }
        return decoded.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(songs) else { return }
        try? data.write(to: Self.fileURL(), options: .atomic)
    }
}
