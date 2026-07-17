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
}

public final class JSONStore: @unchecked Sendable {
    public static let shared: JSONStore = JSONStore(directory: JSONStore.defaultDirectory())

    private let directory: URL
    private let queue = DispatchQueue(label: "com.shaver.bloomcalculator.jsonstore")

    public init(directory: URL) {
        self.directory = directory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    public func get<T: Decodable>(_ key: StoreKey, as type: T.Type) -> T? {
        return queue.sync {
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

    public func set<T: Encodable>(_ key: StoreKey, _ value: T) {
        queue.sync {
            let url = fileURL(for: key)
            guard let data = try? JSONEncoder().encode(value) else {
                return
            }
            do {
                try data.write(to: url, options: .atomic)
            } catch {
                assertionFailure("JSONStore write failed for \(key.rawValue): \(error)")
            }
        }
    }

    public func remove(_ key: StoreKey) {
        queue.sync {
            let url = fileURL(for: key)
            try? FileManager.default.removeItem(at: url)
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
