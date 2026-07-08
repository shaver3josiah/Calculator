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
}

enum KitchenTab: String, CaseIterable {
    case convert, recipe, visualize
}

@Observable
final class KitchenStore {
    var activeTab: KitchenTab = .convert
    var savedRecipes: [SavedRecipe] {
        didSet { JSONStore.shared.set(.recipes, savedRecipes) }
    }

    var convertAmount: Double = 1
    var convertFromUnit: String = "cup"
    var convertToUnit: String = "mL"

    init() {
        savedRecipes = JSONStore.shared.get(.recipes, as: [SavedRecipe].self) ?? []
    }

    func saveRecipe(_ recipe: SavedRecipe) {
        if let idx = savedRecipes.firstIndex(where: { $0.id == recipe.id }) {
            savedRecipes[idx] = recipe
        } else {
            savedRecipes.insert(recipe, at: 0)
        }
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
