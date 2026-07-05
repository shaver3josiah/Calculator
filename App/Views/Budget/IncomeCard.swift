import SwiftUI
import BloomCore

struct IncomeCard: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(BudgetStore.self) private var store

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Money coming in")
                    .font(bloomNumber(17, weight: .semibold))
                    .foregroundStyle(theme.color("deep"))
                Text("Monthly take-home for the two of you. Taxes, retirement, and anything else that comes out of the check.")
                    .font(bloomBody(12))
                    .foregroundStyle(theme.color("muted"))
                VStack(spacing: 12) {
                    ForEach(store.month.inc.indices, id: \.self) { index in
                        incomeRow(index)
                    }
                }
                Toggle(isOn: inc2Binding) {
                    Text("We have a second income")
                        .font(bloomBody(13, weight: .medium))
                        .foregroundStyle(theme.color("text"))
                }
                .tint(theme.color("primaryStrong"))
            }
        }
    }

    private var inc2Binding: Binding<Bool> {
        Binding(get: { store.month.inc2On }, set: { store.setInc2On($0) })
    }

    private func incomeRow(_ index: Int) -> some View {
        let inc = store.month.inc[index]
        let dimmed = index == 1 && !store.month.inc2On
        return VStack(alignment: .leading, spacing: 8) {
            TextField("Income label", text: labelBinding(index))
                .font(bloomBody(13, weight: .semibold))
                .foregroundStyle(theme.color("text"))
            HStack(spacing: 10) {
                fieldGroup(label: "Gross / month", text: grossBinding(index))
            }
            HStack(spacing: 10) {
                fieldGroup(label: "Tax %", text: taxBinding(index))
                fieldGroup(label: "Retire %", text: retBinding(index))
                fieldGroup(label: "Other %", text: othBinding(index))
            }
            Text("Take-home \(Formatters.money(BudgetMath.netOf(inc)))")
                .font(bloomBody(12, weight: .semibold))
                .foregroundStyle(theme.color("good"))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(theme.color("surfaceSoft")))
        .opacity(dimmed ? 0.45 : 1)
    }

    private func fieldGroup(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(bloomBody(10, weight: .medium))
                .foregroundStyle(theme.color("muted"))
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .font(bloomBody(14))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(theme.color("surface"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func labelBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { store.month.inc[index].label },
            set: { store.setIncome(index, label: $0) }
        )
    }

    private func grossBinding(_ index: Int) -> Binding<String> {
        numericBinding(get: { store.month.inc[index].gross }, set: { store.setIncome(index, gross: $0) })
    }

    private func taxBinding(_ index: Int) -> Binding<String> {
        numericBinding(get: { store.month.inc[index].tax }, set: { store.setIncome(index, tax: $0) })
    }

    private func retBinding(_ index: Int) -> Binding<String> {
        numericBinding(get: { store.month.inc[index].ret }, set: { store.setIncome(index, ret: $0) })
    }

    private func othBinding(_ index: Int) -> Binding<String> {
        numericBinding(get: { store.month.inc[index].oth }, set: { store.setIncome(index, oth: $0) })
    }

    private func numericBinding(get: @escaping () -> Double, set: @escaping (Double) -> Void) -> Binding<String> {
        Binding(
            get: { Formatters.plain(get()) },
            set: { newValue in set(Double(newValue) ?? 0) }
        )
    }
}
