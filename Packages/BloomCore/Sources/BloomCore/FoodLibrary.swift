import Foundation

public enum FoodLibrary {
    private static let cache: [Food] = loadFoods()

    public static func load() -> [Food] {
        return cache
    }

    public static func match(_ raw: String) -> Food? {
        let needle = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if needle.isEmpty {
            return nil
        }
        if let exact = cache.first(where: { $0.name.lowercased() == needle }) {
            return exact
        }
        if let prefix = cache.first(where: { $0.name.lowercased().hasPrefix(needle) }) {
            return prefix
        }
        return cache.first(where: { $0.name.lowercased().contains(needle) })
    }

    public static func groups() -> [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for food in cache {
            if !seen.contains(food.group) {
                seen.insert(food.group)
                ordered.append(food.group)
            }
        }
        return ordered
    }

    private static func loadFoods() -> [Food] {
        guard let url = Bundle.module.url(forResource: "foods", withExtension: "json") else {
            return []
        }
        guard let data = try? Data(contentsOf: url) else {
            return []
        }
        guard let foods = try? JSONDecoder().decode([Food].self, from: data) else {
            return []
        }
        return foods
    }
}
