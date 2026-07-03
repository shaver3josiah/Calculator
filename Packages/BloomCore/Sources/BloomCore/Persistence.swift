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
            return try? JSONDecoder().decode(T.self, from: data)
        }
    }

    public func set<T: Encodable>(_ key: StoreKey, _ value: T) {
        queue.sync {
            let url = fileURL(for: key)
            guard let data = try? JSONEncoder().encode(value) else {
                return
            }
            try? data.write(to: url, options: .atomic)
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
