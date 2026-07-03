import SwiftUI
import BloomCore

@Observable
final class MusicStore {
    var chordText: String = ""
    var chords: [ChordVoice] = []
    var tempo: Double = 92
    var strum: Bool = false
    var transpose: Int = 0
    var isPlaying: Bool = false
    var savedSongName: String = ""

    static let samples: [(String, String)] = [
        ("pop", "C G Am F"),
        ("canon", "D A Bm F#m G D G A"),
        ("wedding", "C G Am Em F C Dm G"),
        ("jazz", "Dm7 G7 Cmaj7")
    ]

    private let synth = MusicSynth()
    private var playTask: Task<Void, Never>?

    init() {}

    func loadChords() {
        chords = ChordParser.parseText(chordText)
        transpose = 0
    }

    func playChord(_ voice: ChordVoice) {
        let notes = voice.midiNotes.map { $0 + transpose }
        let duration = 60.0 / tempo * 2.2
        synth.playChord(midiNotes: notes, strum: strum, duration: duration)
    }

    func playAll() {
        guard !chords.isEmpty else { return }
        stopAll()
        isPlaying = true
        let beat = 60.0 / tempo * 2.0
        let sequence = chords
        playTask = Task { @MainActor in
            for chord in sequence {
                guard !Task.isCancelled else { break }
                playChord(chord)
                try? await Task.sleep(nanoseconds: UInt64(beat * 1_000_000_000))
            }
            isPlaying = false
        }
    }

    func stopAll() {
        playTask?.cancel()
        playTask = nil
        isPlaying = false
        synth.stopAll()
    }

    func loadSample(_ key: String) {
        if let match = Self.samples.first(where: { $0.0 == key }) {
            chordText = match.1
            loadChords()
        }
    }

    func saveSong(history: HistoryStore) {
        guard !chords.isEmpty else { return }
        let name = savedSongName.isEmpty ? chordText : savedSongName
        history.add(type: "song", title: name, value: "\(chords.count) chords", extra: ["text": chordText])
    }
}
