import SwiftUI
import BloomCore

struct RuleOf72Panel: View {
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore
    @Environment(DraftStore.self) private var drafts

    @State private var yearsResult: Double = 0

    var body: some View {
        @Bindable var d = drafts
        Card {
            VStack(alignment: .leading, spacing: 16) {
                ProjectionFormField(label: "Return % / yr", text: $d.rule72.rate)
                ProjectionCalcButton(label: "Years to double", action: calculate)
                if drafts.rule72.didCalculate {
                    ProjectionResultStat(label: "Money doubles in about", value: "\(Formatters.plain(yearsResult)) yrs", isGrowth: true)
                }
                ProjectionDisclaimer(text: "Illustrative only. The rule of 72 is a quick estimate. Not financial advice.")
            }
        }
        .onAppear { if drafts.rule72.didCalculate { recompute() } }
    }

    /// The maths only. `calculate()` adds the things that must happen once per
    /// tap — a history row, a sound — and must never fire on a silent replay.
    private func recompute() {
        let rate = Double(drafts.rule72.rate) ?? 0
        yearsResult = FinanceMath.ruleOf72(ratePct: rate)
    }

    private func calculate() {
        recompute()
        drafts.rule72.didCalculate = true

        historyStore.add(
            type: "proj",
            title: "Rule of 72",
            value: "\(Formatters.plain(yearsResult)) yrs",
            extra: ["ratePct": drafts.rule72.rate]
        )
        soundStore.play("success")
    }
}
