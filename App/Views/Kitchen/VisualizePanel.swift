import SwiftUI
import BloomCore
import UIKit

struct VisualizePanel: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(ListsStore.self) private var lists
    @Environment(SoundStore.self) private var sound

    @State private var rawText = ""
    @State private var scale: Double = 1.0
    @State private var customScale = ""
    @State private var useCustom = false
    @State private var parsed: [ParsedIngredient] = []
    @State private var didAttempt = false

    private static let artNames: Set<String> = [
        "croissant", "cupcake", "honeypot", "hotbev", "shortcake", "teacup"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("Paste recipe text", text: $rawText, prompt: Text("Paste recipe text").foregroundColor(theme.color("muted")), axis: .vertical)
                .font(bloomBody(14))
                .foregroundStyle(theme.color("text"))
                .lineLimit(4...8)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surface")))

            scalePicker

            Button("Visualize") {
                parseText()
            }
            .font(bloomBody(14, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 999).fill(theme.color("primaryStrong")))
            .foregroundStyle(.white)

            if !parsed.isEmpty {
                stationGrid
                Button("Add to shopping list") {
                    addAllToList()
                }
                .font(bloomBody(13, weight: .semibold))
                .foregroundStyle(theme.color("primaryStrong"))
            } else if didAttempt {
                Text("Paste a few ingredient lines above, then tap Visualize.")
                    .font(bloomBody(13))
                    .foregroundStyle(theme.color("muted"))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: theme.radius).fill(theme.color("surface")))
    }

    private var scalePicker: some View {
        HStack(spacing: 10) {
            ForEach([0.5, 1.0, 2.0], id: \.self) { value in
                Button(scaleLabel(value)) {
                    useCustom = false
                    scale = value
                }
                .font(bloomBody(13, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 999)
                        .fill(!useCustom && scale == value ? theme.color("primaryStrong") : theme.color("surfaceSoft"))
                )
                .foregroundStyle(!useCustom && scale == value ? .white : theme.color("text"))
            }
            TextField("custom", text: $customScale, prompt: Text("custom").foregroundColor(theme.color("muted")))
                .keyboardType(.decimalPad)
                .font(bloomBody(13))
                .foregroundStyle(theme.color("text"))
                .frame(width: 56)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 8).fill(theme.color("surfaceSoft")))
                .onChange(of: customScale) { _, newValue in
                    if let v = Double(newValue), v > 0 {
                        useCustom = true
                        scale = v
                    }
                }
        }
    }

    private func scaleLabel(_ value: Double) -> String {
        value == 0.5 ? "0.5x" : value == 1.0 ? "1x" : "2x"
    }

    private var stationGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
            ForEach(Array(parsed.enumerated()), id: \.offset) { _, ing in
                stationCard(ing)
            }
        }
    }

    private func stationCard(_ ing: ParsedIngredient) -> some View {
        let scaled = RecipeParse.scale(ing, by: scale)
        let food = FoodLibrary.match(ing.name)
        let fraction = min(max((scaled.qty ?? 1) / 4.0, 0.1), 1.0)

        return VStack(spacing: 8) {
            artView(for: food)
                .frame(height: 56)

            Text(food?.name ?? ing.name.capitalized)
                .font(bloomBody(13, weight: .medium))
                .foregroundStyle(theme.color("text"))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(scaledLabel(scaled))
                .font(bloomNumber(15, weight: .semibold))
                .foregroundStyle(theme.color("deep"))

            measuringFill(fraction)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14).fill(theme.color("surfaceSoft")))
    }

    private func scaledLabel(_ ing: ParsedIngredient) -> String {
        guard let qty = ing.qty else { return ing.unit ?? "" }
        let qtyText = RecipeParse.fmtQty(qty)
        guard let unit = ing.unit else { return qtyText }
        return "\(qtyText) \(unit)"
    }

    @ViewBuilder
    private func artView(for food: Food?) -> some View {
        if let key = food?.artKey, Self.artNames.contains(key), let uiImage = Self.loadArt(key) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else {
            Text(food?.glyph ?? "🥣")
                .font(.system(size: 34))
        }
    }

    private static var artCache: [String: UIImage] = [:]

    private static func loadArt(_ key: String) -> UIImage? {
        if let cached = artCache[key] {
            return cached
        }
        guard let resolved = resolveArt(key) else {
            return nil
        }
        artCache[key] = resolved
        return resolved
    }

    private static func resolveArt(_ key: String) -> UIImage? {
        if let named = UIImage(named: key) {
            return named
        }
        let subdirectories = ["FoodArt/png", "Resources/FoodArt/png"]
        for subdirectory in subdirectories {
            if let url = Bundle.main.url(forResource: key, withExtension: "png", subdirectory: subdirectory),
               let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                return image
            }
        }
        if let url = Bundle.main.url(forResource: key, withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            return image
        }
        return nil
    }

    private func measuringFill(_ fraction: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(theme.color("surface"))
                RoundedRectangle(cornerRadius: 4)
                    .fill(theme.color("primary"))
                    .frame(height: geo.size.height * fraction)
            }
        }
        .frame(height: 8)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func parseText() {
        let lines = rawText.split(separator: "\n").map(String.init)
        parsed = lines.compactMap { RecipeParse.parseLine($0) }
        didAttempt = true
        sound.play("tap1")
    }

    private func addAllToList() {
        for ing in parsed {
            lists.addIngredient(name: ing.name)
        }
        sound.play("success")
    }
}
