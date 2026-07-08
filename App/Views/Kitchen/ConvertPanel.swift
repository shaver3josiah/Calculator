import SwiftUI
import BloomCore

struct ConvertPanel: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(KitchenStore.self) private var store

    private static let maxWholeCups = 12
    private static let cupGlyphHeight: CGFloat = 50
    private static let cupGridColumns = [GridItem(.adaptive(minimum: 44, maximum: 56), spacing: 10)]

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
        } else if store.convertCups > 1 {
            multiCupIllustration
        } else {
            VesselFill(fraction: store.convertFraction)
        }
    }

    private var multiCupIllustration: some View {
        let cups = store.convertCups
        let flooredCups = cups.rounded(.down)
        let remainder = cups - flooredCups
        let showsPartial = remainder >= 0.05
        let cappedFloor = min(flooredCups, Double(Self.maxWholeCups))
        let fullCupCount = max(Int(cappedFloor), 0)

        return VStack(spacing: 10) {
            LazyVGrid(columns: Self.cupGridColumns, spacing: 10) {
                ForEach(0..<fullCupCount, id: \.self) { _ in
                    VesselFill(fraction: 1.0, height: Self.cupGlyphHeight)
                }
                if showsPartial {
                    VesselFill(fraction: remainder, height: Self.cupGlyphHeight)
                }
            }
            Text(cupsLabelText(cups))
                .font(bloomNumber(15, weight: .semibold))
                .foregroundStyle(theme.color("text"))
        }
    }

    private func cupsLabelText(_ cups: Double) -> String {
        let rounded = (cups * 100).rounded() / 100
        return "\(Formatters.fmt(rounded)) cups"
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
