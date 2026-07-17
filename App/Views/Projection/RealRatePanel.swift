import SwiftUI
import BloomCore

struct RealRatePanel: View {
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore
    @Environment(DraftStore.self) private var drafts

    @State private var realResult: Double = 0

    var body: some View {
        @Bindable var d = drafts
        Card {
            VStack(alignment: .leading, spacing: 16) {
                ProjectionFieldRow(leftLabel: "Nominal return %", leftText: $d.realRate.nominal, rightLabel: "Inflation %", rightText: $d.realRate.inflation)
                ProjectionCalcButton(label: "Find the real rate", action: calculate)
                if drafts.realRate.didCalculate {
                    ProjectionResultStat(label: "Real return / yr", value: "\(Formatters.plain(realResult))%", isGrowth: true)
                }
                ProjectionDisclaimer(text: "Illustrative only. Real rate is growth after inflation. Not financial advice.")
            }
        }
        .onAppear { if drafts.realRate.didCalculate { recompute() } }
    }

    /// The maths only. `calculate()` adds the things that must happen once per
    /// tap — a history row, a sound — and must never fire on a silent replay.
    private func recompute() {
        let nominal = Double(drafts.realRate.nominal) ?? 0
        let inflation = Double(drafts.realRate.inflation) ?? 0
        realResult = FinanceMath.realRate(nominalPct: nominal, inflationPct: inflation)
    }

    private func calculate() {
        recompute()
        drafts.realRate.didCalculate = true

        historyStore.add(
            type: "proj",
            title: "Real rate",
            value: "\(Formatters.plain(realResult))%",
            extra: ["nominalPct": drafts.realRate.nominal, "inflationPct": drafts.realRate.inflation]
        )
        soundStore.play("success")
    }
}
