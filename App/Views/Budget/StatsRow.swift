import SwiftUI
import BloomCore

/// The month's real-dollar bottom line: take-home, minus giving, minus planned
/// spending, down to what's actually free to grow. (File keeps its old name so
/// history stays traceable — this replaced the old three-stat strip.)
struct StatsRow: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(BudgetStore.self) private var store

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("The bottom line")
                    .font(bloomNumber(17, weight: .semibold))
                    .foregroundStyle(theme.color("deep"))
                line(label: "Take-home", value: "+" + Formatters.money(store.takeHome))
                if store.stewardshipTotal > 0 {
                    line(label: "Giving", value: "\u{2212}" + Formatters.money(store.stewardshipTotal))
                }
                line(label: "Planned spending", value: "\u{2212}" + Formatters.money(store.planned))
                Rectangle().fill(theme.color("line")).frame(height: 1)
                heroLine
            }
        }
    }

    private var heroLine: some View {
        let value = store.trueLeftOver
        let negative = value < 0
        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("Left to grow")
                    .font(bloomBody(13, weight: .semibold))
                    .foregroundStyle(theme.color("text"))
                Spacer()
                Text((negative ? "\u{2212}" : "") + Formatters.money(abs(value)))
                    .font(bloomNumber(28, weight: .semibold))
                    .foregroundStyle(negative ? theme.color("deep") : theme.color("good"))
            }
            if negative {
                Text("a touch over \u{2014} trim \(Formatters.money(abs(value))) somewhere soft")
                    .font(bloomBody(11))
                    .foregroundStyle(theme.color("muted"))
            }
        }
    }

    private func line(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(bloomBody(13))
                .foregroundStyle(theme.color("muted"))
            Spacer()
            Text(value)
                .font(bloomNumber(15, weight: .semibold))
                .foregroundStyle(theme.color("text"))
        }
    }
}
