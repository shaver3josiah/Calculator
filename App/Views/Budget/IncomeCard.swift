import SwiftUI
import BloomCore

struct IncomeCard: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(BudgetStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showWifeySplash = false

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
                        // Row 1 (the second income) is present only while inc2On;
                        // toggling off pops it out, re-enabling inserts it gently.
                        if index == 1 {
                            if store.month.inc2On {
                                incomeRow(index)
                                    .transition(secondIncomeTransition)
                            }
                        } else {
                            incomeRow(index)
                        }
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
        .fullScreenCover(isPresented: $showWifeySplash) {
            WifeySplash()
        }
    }

    /// Pop out on removal (scale up + fade), slip in gently on insertion.
    private var secondIncomeTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.98)),
            removal: .opacity.combined(with: .scale(scale: 1.06))
        )
    }

    private var inc2Binding: Binding<Bool> {
        Binding(
            get: { store.month.inc2On },
            set: { newValue in
                let wasOn = store.month.inc2On
                if theme.motionEnabled && !reduceMotion {
                    withAnimation(BloomMotion.springSoft) {
                        store.setInc2On(newValue)
                    }
                } else {
                    store.setInc2On(newValue)
                }
                // The moment: only on the true → false transition.
                if wasOn && !newValue {
                    showWifeySplash = true
                }
            }
        )
    }

    private func incomeRow(_ index: Int) -> some View {
        let inc = store.month.inc[index]
        return VStack(alignment: .leading, spacing: 8) {
            TextField("Income label", text: labelBinding(index), prompt: Text("Income label").foregroundStyle(theme.color("muted")))
                .font(bloomBody(13, weight: .semibold))
                .foregroundStyle(theme.color("text"))
                .inputAccessories(labelBinding(index), compact: true)
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
    }

    private func fieldGroup(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(bloomBody(10, weight: .medium))
                .foregroundStyle(theme.color("muted"))
            TextField("0", text: text, prompt: Text("0").foregroundStyle(theme.color("muted")))
                .keyboardType(.decimalPad)
                .font(bloomBody(14))
                .inputAccessories(text, compact: true)
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
