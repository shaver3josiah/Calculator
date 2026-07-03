import SwiftUI
import BloomCore

struct ConvertPanel: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(KitchenStore.self) private var store

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Amount")
                        .font(bloomBody(12))
                        .foregroundStyle(theme.color("muted"))
                    TextField("1", value: amountBinding, format: .number)
                        .keyboardType(.decimalPad)
                        .font(bloomNumber(18))
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

            VesselFill(fraction: store.convertFraction)
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
