import SwiftUI
import Charts
import BloomCore

struct ComparePanel: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(ProjectionStore.self) private var projectionStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(DraftStore.self) private var drafts

    @State private var series: [FundSeries] = []

    var body: some View {
        @Bindable var d = drafts
        Card {
            VStack(alignment: .leading, spacing: 16) {
                ProjectionFieldRow(leftLabel: "Monthly added", leftText: $d.compare.monthly, rightLabel: "Years", rightText: $d.compare.years)
                ProjectionFormField(label: "Starting balance", text: $d.compare.start)
                ProjectionCalcButton(label: "Compare the fund profiles", action: calculate)
                if drafts.compare.didCalculate {
                    compareChart
                    fundLegend
                }
                ProjectionDisclaimer(text: "Illustrative only. Same contributions across your saved fund profiles. Not financial advice.")
            }
        }
        .onAppear { if drafts.compare.didCalculate { recompute() } }
    }

    private var compareChart: some View {
        Chart {
            ForEach(series) { fundSeries in
                ForEach(fundSeries.points) { point in
                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Balance", point.balance)
                    )
                    .foregroundStyle(by: .value("Fund", fundSeries.name))
                }
            }
        }
        .chartForegroundStyleScale(range: chartColors)
        .frame(height: 170)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .accessibilityLabel("Fund comparison chart")
        .accessibilityValue(series.map { "\($0.name) ends at \(Formatters.money($0.finalBalance))" }.joined(separator: ", "))
        .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: series.count)
    }

    private var chartColors: [Color] {
        [themeStore.color("primary"), themeStore.color("primaryStrong"), themeStore.color("deep"), themeStore.color("good")]
    }

    private var fundLegend: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(series) { fundSeries in
                HStack {
                    Text(fundSeries.name)
                        .font(bloomBody(13, weight: .medium))
                        .foregroundStyle(themeStore.color("text"))
                    Spacer()
                    Text(Formatters.money(fundSeries.finalBalance))
                        .font(bloomBody(13, weight: .semibold))
                        .foregroundStyle(themeStore.color("good"))
                }
            }
        }
    }

    /// The maths only. `calculate()` adds the things that must happen once per
    /// tap — a history row, a sound — and must never fire on a silent replay.
    private func recompute() {
        let monthly = Double(drafts.compare.monthly) ?? 0
        let years = Double(drafts.compare.years) ?? 0
        let start = Double(drafts.compare.start) ?? 0
        let totalYears = years.isFinite ? Int(min(max(years, 1), 100)) : 1  // ponytail: clamp free-text years; NaN guard because Double("nan") parses

        series = projectionStore.funds.map { fund in
            var points: [FundPoint] = []
            for year in 0...totalYears {
                let balance = FinanceMath.futureValue(principal: start, monthly: monthly, annualRatePct: fund.ratePct, years: Double(year))
                points.append(FundPoint(year: year, balance: balance))
            }
            let final = points.last?.balance ?? 0
            return FundSeries(id: fund.id, name: fund.name, points: points, finalBalance: final)
        }
    }

    private func calculate() {
        recompute()
        drafts.compare.didCalculate = true

        var extra = ["monthly": drafts.compare.monthly, "years": drafts.compare.years, "start": drafts.compare.start]
        for fundSeries in series {
            extra[fundSeries.name] = Formatters.money(fundSeries.finalBalance)
        }
        historyStore.add(type: "proj", title: "Compare", value: "\(series.count) funds", extra: extra)
        soundStore.play("success")
    }
}

private struct FundPoint: Identifiable {
    let year: Int
    let balance: Double
    var id: Int { year }
}

private struct FundSeries: Identifiable {
    let id: UUID
    let name: String
    let points: [FundPoint]
    let finalBalance: Double
}
