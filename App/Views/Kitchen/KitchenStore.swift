import SwiftUI
import BloomCore

struct SavedRecipe: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var serves: String
    var time: String
    var ingredients: [String]
    var steps: [String]
    var notes: String
    var savedAt: Date = Date()
    /// The page a link recipe came from. Optional: recipes saved before this
    /// field existed decode without it (their link, if any, is in `notes`).
    var sourceUrl: String?
}

enum KitchenTab: String, CaseIterable {
    case convert, recipe, visualize
}

/// The two procedurally-drawn Visualize countertop finishes.
enum CounterFinish: String, CaseIterable {
    case marble, wood
}

@Observable
final class KitchenStore {
    var activeTab: KitchenTab = .convert
    var savedRecipes: [SavedRecipe] {
        didSet { JSONStore.shared.set(.recipes, savedRecipes) }
    }

    // Persisted the same way as savedRecipes: raw value written on every change.
    var counterFinish: CounterFinish {
        didSet { JSONStore.shared.set(.counterTop, counterFinish.rawValue) }
    }

    var convertAmount: Double = 1
    var convertFromUnit: String = "cup"
    var convertToUnit: String = "mL"

    init() {
        savedRecipes = JSONStore.shared.get(.recipes, as: [SavedRecipe].self) ?? []
        let savedFinish = JSONStore.shared.get(.counterTop, as: String.self) ?? ""
        counterFinish = CounterFinish(rawValue: savedFinish) ?? .marble
    }

    /// Inserts a new recipe, or replaces the saved one with the same id.
    /// Returns true when it was an update.
    @discardableResult
    func saveRecipe(_ recipe: SavedRecipe) -> Bool {
        if let idx = savedRecipes.firstIndex(where: { $0.id == recipe.id }) {
            savedRecipes[idx] = recipe
            return true
        }
        savedRecipes.insert(recipe, at: 0)
        return false
    }

    func contains(_ id: UUID?) -> Bool {
        guard let id else { return false }
        return savedRecipes.contains { $0.id == id }
    }

    func deleteRecipe(_ id: UUID) {
        savedRecipes.removeAll { $0.id == id }
    }

    var convertedValue: Double? {
        UnitConvert.convert(convertAmount, from: convertFromUnit, to: convertToUnit)
    }

    var convertFraction: Double {
        guard let cupValue = UnitConvert.convert(convertAmount, from: convertFromUnit, to: "cup") else {
            return 0
        }
        return min(max(cupValue, 0), 1.6)
    }

    var convertWeightFraction: Double {
        guard let gramsValue = UnitConvert.convert(convertAmount, from: convertFromUnit, to: "g") else {
            return 0
        }
        return min(max(gramsValue / 453.592, 0), 2.0)
    }

    var convertCups: Double {
        UnitConvert.convert(convertAmount, from: convertFromUnit, to: "cup") ?? 0
    }
}
