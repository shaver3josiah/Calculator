import Foundation

public enum StoreKey: String, CaseIterable, Sendable {
    case history = "bloom_history"
    case favorites = "bloom_favorites"
    case funds = "bloom_funds"
    case theme = "bloom_theme"
    case custom = "bloom_custom"
    case soundmap = "bloom_soundmap"
    case recipes = "bloom_recipes"
    case shopLists = "bloomShopLists"
    case memory = "bloom_memory"
    case songs = "bloom_songs"
    case budget2 = "bloom_budget2"
    case tabLabels = "bloom_tablabels"
    case motion = "bloom_motion"
    case counterTop = "bloom_countertop"
    case calcLog = "bloom_calclog"
    case chordWheel = "bloom_chordwheel"
    case stewardship = "bloom_stewardship"
    case keyStyle = "bloom_keystyle"
    case lightPreset = "bloom_lightpreset"
    case drafts = "bloom_drafts"
    case orientation = "bloom_orientation"
    case calcDecimals = "bloom_calcdecimals"
    case notesArchive = "bloom_notesarchive"
}

public final class JSONStore: @unchecked Sendable {
    public static let shared: JSONStore = JSONStore(directory: JSONStore.defaultDirectory())

    private let directory: URL
    private let queue = DispatchQueue(label: "com.shaver.bloomcalculator.jsonstore")
    /// Encoded values waiting on the debounce, newest per key. Touched only on `queue`.
    private var pending: [StoreKey: Data] = [:]
    private var flushScheduled = false
    // ponytail: one debounce for every key. Long enough to swallow a typing burst,
    // short enough that a hard kill loses at most this much; scenePhase flushes the
    // normal path. Per-key intervals only if some key ever needs its own.
    private static let debounce: DispatchTimeInterval = .milliseconds(500)

    public init(directory: URL) {
        self.directory = directory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    public func get<T: Decodable>(_ key: StoreKey, as type: T.Type) -> T? {
        return queue.sync {
            // Read-your-writes: a value still waiting on the debounce is the
            // truth, not the older copy still sitting on disk.
            if let queued = pending[key] {
                return try? JSONDecoder().decode(T.self, from: queued)
            }
            let url = fileURL(for: key)
            guard let data = try? Data(contentsOf: url) else {
                return nil
            }
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                // Preserve the unreadable file so the next save can't overwrite the evidence.
                let aside = url.appendingPathExtension("corrupt")
                try? FileManager.default.removeItem(at: aside)
                try? FileManager.default.moveItem(at: url, to: aside)
                return nil
            }
        }
    }

    /// Coalesced and off the caller's thread. Every store calls this from a
    /// `didSet`, so at the top of a burst of typing it fired once per keystroke:
    /// a full encode plus an atomic write, synchronously, on the main thread.
    /// Only the LAST value per key can ever reach disk, so the burst collapses
    /// to one write `debounce` after it stops.
    public func set<T: Encodable>(_ key: StoreKey, _ value: T) {
        queue.async {
            guard let data = try? JSONEncoder().encode(value) else { return }
            self.pending[key] = data
            guard !self.flushScheduled else { return }
            self.flushScheduled = true
            self.queue.asyncAfter(deadline: .now() + Self.debounce) { self.writePending() }
        }
    }

    public func remove(_ key: StoreKey) {
        queue.sync {
            // Drop the queued write too, or the debounce resurrects the file.
            pending[key] = nil
            let url = fileURL(for: key)
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// Write everything queued, right now. Call when the app leaves the screen:
    /// the debounce window is the one span where her last edit lives only in
    /// memory. Blocks until the bytes are handed to the filesystem.
    public func flush() {
        queue.sync { writePending() }
    }

    /// Must run on `queue`.
    private func writePending() {
        flushScheduled = false
        let batch = pending
        pending.removeAll()
        for (key, data) in batch {
            do {
                try data.write(to: fileURL(for: key), options: .atomic)
            } catch {
                // A write can genuinely fail (disk full, protected data locked
                // while the phone is still locked). Dropping the bytes here
                // would lose the edit silently, and assertionFailure is compiled
                // out in Release, so the old code lost it with NO signal at all.
                // Put it back so the next flush retries - unless a newer value
                // for the same key already landed in the queue behind us.
                if pending[key] == nil { pending[key] = data }
                assertionFailure("JSONStore write failed for \(key.rawValue): \(error)")
            }
        }
        // Something failed and is waiting for another go.
        if !pending.isEmpty, !flushScheduled {
            flushScheduled = true
            queue.asyncAfter(deadline: .now() + Self.debounce) { self.writePending() }
        }
    }

    private func fileURL(for key: StoreKey) -> URL {
        return directory.appendingPathComponent(key.rawValue).appendingPathExtension("json")
    }

    private static func defaultDirectory() -> URL {
        let fm = FileManager.default
        if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let bloomDir = appSupport.appendingPathComponent("Bloom", isDirectory: true)
            if (try? fm.createDirectory(at: bloomDir, withIntermediateDirectories: true)) != nil {
                return bloomDir
            }
        }
        return fm.temporaryDirectory
    }
}
