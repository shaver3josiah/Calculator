import SwiftUI
import BloomCore

struct RetirePanel: View {
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore
    @Environment(DraftStore.self) private var drafts

    @State private var futureResult: Double = 0
    @State private var todayResult: Double = 0

    var body: some View {
        @Bindable var d = drafts
        Card {
            VStack(alignment: .leading, spacing: 16) {
                ProjectionFieldRow(leftLabel: "Current age", leftText: $d.retire.age, rightLabel: "Retire at", rightText: $d.retire.retireAge)
                ProjectionFieldRow(leftLabel: "You add monthly", leftText: $d.retire.monthly, rightLabel: "Employer monthly", rightText: $d.retire.employer)
                ProjectionFieldRow(leftLabel: "Return % / yr", leftText: $d.retire.rate, rightLabel: "Inflation % / yr", rightText: $d.retire.inflation)
                ProjectionFormField(label: "Starting balance", text: $d.retire.start)
                ProjectionCalcButton(label: "See the nest egg", action: calculate)
                if drafts.retire.didCalculate {
                    HStack(spacing: 20) {
                        ProjectionResultStat(label: "At retirement", value: Formatters.money(futureResult))
                        ProjectionResultStat(label: "In today's dollars", value: Formatters.money(todayResult), isGrowth: true)
                    }
                }
                ProjectionDisclaimer(text: "Illustrative only. You enter every assumption. Not financial advice, and no live trading.")
            }
        }
        .onAppear { if drafts.retire.didCalculate { recompute() } }
    }

    /// The maths only. `calculate()` adds the things that must happen once per
    /// tap — a history row, a sound — and must never fire on a silent replay.
    private func recompute() {
        let age = Double(drafts.retire.age) ?? 0
        let retireAge = Double(drafts.retire.retireAge) ?? 0
        let monthly = Double(drafts.retire.monthly) ?? 0
        let employer = Double(drafts.retire.employer) ?? 0
        let rate = Double(drafts.retire.rate) ?? 0
        let inflation = Double(drafts.retire.inflation) ?? 0
        let start = Double(drafts.retire.start) ?? 0
        let years = max(retireAge - age, 0)

        let totalMonthly = monthly + employer
        futureResult = FinanceMath.futureValue(principal: start, monthly: totalMonthly, annualRatePct: rate, years: years)
        let real = FinanceMath.realRate(nominalPct: rate, inflationPct: inflation)
        todayResult = FinanceMath.futureValue(principal: start, monthly: totalMonthly, annualRatePct: real, years: years)
    }

    private func calculate() {
        recompute()
        drafts.retire.didCalculate = true

        historyStore.add(
            type: "proj",
            title: "Retire",
            value: Formatters.money(futureResult),
            extra: [
                "age": drafts.retire.age,
                "retireAge": drafts.retire.retireAge,
                "monthly": drafts.retire.monthly,
                "employer": drafts.retire.employer,
                "ratePct": drafts.retire.rate,
                "inflationPct": drafts.retire.inflation,
                "start": drafts.retire.start
            ]
        )
        soundStore.play("success")
    }
}
