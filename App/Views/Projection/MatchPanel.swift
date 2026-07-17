import SwiftUI
import BloomCore

struct MatchPanel: View {
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore
    @Environment(DraftStore.self) private var drafts

    @State private var capturedResult: Double = 0
    @State private var leftOnTableResult: Double = 0

    var body: some View {
        @Bindable var d = drafts
        Card {
            VStack(alignment: .leading, spacing: 16) {
                ProjectionFormField(label: "Annual salary", text: $d.match.salary)
                ProjectionFieldRow(leftLabel: "You contribute %", leftText: $d.match.yourPct, rightLabel: "Match rate %", rightText: $d.match.matchRate)
                ProjectionFormField(label: "Match up to % of salary", text: $d.match.matchCap)
                ProjectionCalcButton(label: "Check the match", action: calculate)
                if drafts.match.didCalculate {
                    HStack(spacing: 20) {
                        ProjectionResultStat(label: "Match captured / yr", value: Formatters.money(capturedResult), isGrowth: true)
                        ProjectionResultStat(label: "Left on the table / yr", value: Formatters.money(leftOnTableResult))
                    }
                }
                ProjectionDisclaimer(text: "Illustrative only. Left on the table is the match you are not yet capturing. Not financial advice.")
            }
        }
        .onAppear { if drafts.match.didCalculate { recompute() } }
    }

    /// The maths only. `calculate()` adds the things that must happen once per
    /// tap — a history row, a sound — and must never fire on a silent replay.
    private func recompute() {
        let salary = Double(drafts.match.salary) ?? 0
        let yourPct = Double(drafts.match.yourPct) ?? 0
        let matchRate = Double(drafts.match.matchRate) ?? 0
        let matchCap = Double(drafts.match.matchCap) ?? 0

        capturedResult = FinanceMath.employerMatch(salary: salary, contribPct: yourPct, matchPct: matchRate, matchLimitPct: matchCap)
        let maxCaptured = FinanceMath.employerMatch(salary: salary, contribPct: matchCap, matchPct: matchRate, matchLimitPct: matchCap)
        leftOnTableResult = max(maxCaptured - capturedResult, 0)
    }

    private func calculate() {
        recompute()
        drafts.match.didCalculate = true

        historyStore.add(
            type: "proj",
            title: "Match",
            value: Formatters.money(capturedResult),
            extra: [
                "salary": drafts.match.salary,
                "yourPct": drafts.match.yourPct,
                "matchRatePct": drafts.match.matchRate,
                "matchCapPct": drafts.match.matchCap
            ]
        )
        soundStore.play("success")
    }
}
