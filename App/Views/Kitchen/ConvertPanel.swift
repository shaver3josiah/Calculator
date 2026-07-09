import SwiftUI
import BloomCore

struct ConvertPanel: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(KitchenStore.self) private var store

    private static let maxGlyphs = 16
    private static let cupGlyphHeight: CGFloat = 50
    private static let spoonGlyphHeight: CGFloat = 46
    private static let glyphColumns = [GridItem(.adaptive(minimum: 44, maximum: 56), spacing: 10)]
    private static let countableUnits: Set<String> = ["tsp", "tbsp", "cup"]

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Amount")
                        .font(bloomBody(12))
                        .foregroundStyle(theme.color("muted"))
                    TextField("1", value: amountBinding, format: .number, prompt: Text("1").foregroundColor(theme.color("muted")))
                        .keyboardType(.decimalPad)
                        .font(bloomNumber(18))
                        .foregroundStyle(theme.color("text"))
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(theme.color("surface"))
                        )
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("From")
                        .font(bloomBody(12))
                        .foregroundStyle(theme.color("muted"))
                    Picker("From", selection: fromBinding) {
                        unitOptions
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("To")
                        .font(bloomBody(12))
                        .foregroundStyle(theme.color("muted"))
                    Picker("To", selection: toBinding) {
                        unitOptions
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }

            convertIllustration
                .padding(.horizontal, 20)

            resultCard

            Text("Conversions stay within a family, volume to volume and weight to weight.")
                .font(bloomBody(11))
                .foregroundStyle(theme.color("muted"))
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.radius)
                .fill(theme.color("surface"))
        )
    }

    private var unitOptions: some View {
        Group {
            ForEach(UnitConvert.volumeUnits, id: \.self) { unit in
                Text(unit).tag(unit)
            }
            ForEach(UnitConvert.weightUnits, id: \.self) { unit in
                Text(unit).tag(unit)
            }
        }
    }

    @ViewBuilder
    private var convertIllustration: some View {
        if UnitConvert.weightUnits.contains(store.convertToUnit) {
            ScaleFill(fraction: store.convertWeightFraction)
        } else if Self.countableUnits.contains(store.convertToUnit), let value = store.convertedValue, value > 0 {
            targetCountIllustration(value: value, unit: store.convertToUnit)
        } else {
            VesselFill(fraction: store.convertFraction)
        }
    }

    private func targetCountIllustration(value: Double, unit: String) -> some View {
        let floored = (value + 1e-3).rounded(.down)
        let remainder = value - floored
        let showsPartial = remainder >= 0.05
        let fullCount = max(Int(floored), 0)
        let cappedCount = min(fullCount, Self.maxGlyphs)
        let overflow = fullCount > Self.maxGlyphs

        return VStack(spacing: 10) {
            LazyVGrid(columns: Self.glyphColumns, spacing: 10) {
                ForEach(0..<cappedCount, id: \.self) { _ in
                    measureGlyph(unit: unit, fraction: 1.0)
                }
                if showsPartial && !overflow {
                    measureGlyph(unit: unit, fraction: remainder)
                }
            }
            Text(targetLabel(value, unit))
                .font(bloomNumber(15, weight: .semibold))
                .foregroundStyle(theme.color("text"))
        }
    }

    @ViewBuilder
    private func measureGlyph(unit: String, fraction: Double) -> some View {
        if unit == "cup" {
            VesselFill(fraction: fraction, height: Self.cupGlyphHeight)
        } else {
            SpoonGlyphFill(fraction: fraction, height: Self.spoonGlyphHeight)
        }
    }

    private func targetLabel(_ value: Double, _ unit: String) -> String {
        let rounded = (value * 100).rounded() / 100
        return "\(Formatters.fmt(rounded)) \(unit)"
    }

    private var resultCard: some View {
        VStack(spacing: 4) {
            if let converted = store.convertedValue {
                Text(Formatters.fmt(converted))
                    .font(bloomNumber(28, weight: .semibold))
                    .foregroundStyle(theme.color("deep"))
                Text(store.convertToUnit)
                    .font(bloomBody(13))
                    .foregroundStyle(theme.color("muted"))
            } else {
                Text("Pick units from the same family")
                    .font(bloomBody(13))
                    .foregroundStyle(theme.color("muted"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.color("surfaceSoft"))
        )
    }

    private var amountBinding: Binding<Double> {
        Binding(get: { store.convertAmount }, set: { store.convertAmount = $0 })
    }
    private var fromBinding: Binding<String> {
        Binding(get: { store.convertFromUnit }, set: { store.convertFromUnit = $0 })
    }
    private var toBinding: Binding<String> {
        Binding(get: { store.convertToUnit }, set: { store.convertToUnit = $0 })
    }
}
