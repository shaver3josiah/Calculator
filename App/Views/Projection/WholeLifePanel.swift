import SwiftUI
import Charts
import BloomCore

/// A whole-life projection with a Northwestern Mutual dividend-rate reference.
/// This is a deliberately simplified ballpark — NOT a policy illustration. It
/// always draws the guaranteed (lower) line beside the projected one so the
/// non-guaranteed part is never mistaken for a promise, and it says plainly that
/// the app isn't affiliated with Northwestern Mutual. A real number comes from a
/// licensed agent's illustration.
struct WholeLifePanel: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(DraftStore.self) private var drafts

    @State private var series: [FinanceMath.WholeLifeYear] = []

    var body: some View {
        @Bindable var d = drafts
        Card {
            VStack(alignment: .leading, spacing: 16) {
                Text("Whole life insurance")
                    .font(bloomNumber(17, weight: .semibold))
                    .foregroundStyle(themeStore.color("deep"))

                referenceNote

                ProjectionFieldRow(
                    leftLabel: "Annual premium",
                    leftText: $d.wholeLife.annualPremium,
                    rightLabel: "Years paying",
                    rightText: $d.wholeLife.yearsPaying
                )
                ProjectionFieldRow(
                    leftLabel: "Death benefit",
                    leftText: $d.wholeLife.initialDeathBenefit,
                    rightLabel: "Dividend rate %",
                    rightText: $d.wholeLife.assumedRate
                )
                projectionYearsSlider
                DisclosureGroup {
                    ProjectionFormField(label: "Premium reaching cash value % (efficiency)", text: $d.wholeLife.efficiency)
                    Text("Early premiums pay for insurance and costs before building cash value. Lower this for a more conservative early cash value.")
                        .font(bloomBody(11))
                        .foregroundStyle(themeStore.color("muted"))
                        .padding(.top, 4)
                } label: {
                    Text("Fine tuning")
                        .font(bloomBody(13, weight: .semibold))
                        .foregroundStyle(themeStore.color("accentInk"))
                }
                .tint(themeStore.color("accentInk"))

                ProjectionCalcButton(label: "Project the policy", action: calculate)
                if drafts.wholeLife.didCalculate, let last = series.last {
                    resultSection(last)
                }
                ProjectionDisclaimer(text: "A simplified ballpark, NOT a policy illustration. Dividends are not guaranteed — the lower line is the conservative floor. This app is not affiliated with, endorsed by, or a substitute for Northwestern Mutual. For real numbers, ask a licensed agent for an illustration. Not financial advice.")
            }
        }
        .onAppear {
            if drafts.wholeLife.didCalculate { recompute() }
        }
    }

    private var referenceNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(themeStore.color("muted"))
            Text("Reference: Northwestern Mutual's 2026 dividend interest rate is 5.75%. It's a starting point you can change, not a projected return.")
                .font(bloomBody(11))
                .foregroundStyle(themeStore.color("muted"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(themeStore.color("surfaceSoft")))
    }

    private var projectionYearsSlider: some View {
        let years = Int(Double(drafts.wholeLife.projectionYears) ?? 30)
        return VStack(alignment: .leading, spacing: 6) {
            Text("Project \(years) years out")
                .font(bloomBody(12, weight: .medium))
                .foregroundStyle(themeStore.color("muted"))
            Slider(
                value: Binding(
                    get: { Double(drafts.wholeLife.projectionYears) ?? 30 },
                    set: { drafts.wholeLife.projectionYears = String(Int($0)) }
                ),
                in: 5...60, step: 1
            )
            .tint(themeStore.color("primaryStrong"))
        }
    }

    private func resultSection(_ last: FinanceMath.WholeLifeYear) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                FlowerLogo(size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("PROJECTED CASH VALUE")
                        .font(bloomBody(10, weight: .semibold))
                        .foregroundStyle(themeStore.color("muted"))
                    RollingNumberText(
                        text: Formatters.money(last.cashValue),
                        font: bloomNumber(28, weight: .semibold),
                        color: themeStore.color("deep")
                    )
                }
            }
            HStack(spacing: 20) {
                ProjectionResultStat(label: "Guaranteed floor", value: Formatters.money(last.guaranteedCashValue))
                ProjectionResultStat(label: "Death benefit", value: Formatters.money(last.deathBenefit), isGrowth: true)
            }
            if series.count > 1 {
                chart
                Text("Solid: projected (dividends aren't guaranteed).  Dashed: guaranteed floor.")
                    .font(bloomBody(10))
                    .foregroundStyle(themeStore.color("muted"))
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(series, id: \.year) { point in
                AreaMark(x: .value("Year", point.year), y: .value("Cash value", point.cashValue))
                    .foregroundStyle(themeStore.color("primary").opacity(0.18))
            }
            ForEach(series, id: \.year) { point in
                LineMark(x: .value("Year", point.year), y: .value("Cash value", point.cashValue))
                    .foregroundStyle(themeStore.color("primaryStrong"))
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
            ForEach(series, id: \.year) { point in
                LineMark(x: .value("Year", point.year), y: .value("Guaranteed", point.guaranteedCashValue))
                    .foregroundStyle(themeStore.color("muted"))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            }
        }
        .frame(height: 160)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .accessibilityLabel("Projected versus guaranteed cash value")
        .accessibilityValue("Projected \(Formatters.money(series.last?.cashValue ?? 0)), guaranteed \(Formatters.money(series.last?.guaranteedCashValue ?? 0))")
        .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: series.count)
    }

    private func recompute() {
        series = FinanceMath.wholeLifeSeries(
            annualPremium: Double(drafts.wholeLife.annualPremium) ?? 0,
            yearsPaying: Int(Double(drafts.wholeLife.yearsPaying) ?? 20),
            projectionYears: Int(Double(drafts.wholeLife.projectionYears) ?? 30),
            ratePct: Double(drafts.wholeLife.assumedRate) ?? 5.75,
            initialDeathBenefit: Double(drafts.wholeLife.initialDeathBenefit) ?? 0,
            efficiencyPct: Double(drafts.wholeLife.efficiency) ?? 85
        )
    }

    private func calculate() {
        recompute()
        drafts.wholeLife.didCalculate = true
        historyStore.add(
            type: "proj",
            title: "Whole life",
            value: Formatters.money(series.last?.cashValue ?? 0),
            extra: [
                "premium": drafts.wholeLife.annualPremium,
                "years": drafts.wholeLife.projectionYears,
                "ratePct": drafts.wholeLife.assumedRate,
                "deathBenefit": drafts.wholeLife.initialDeathBenefit
            ]
        )
        soundStore.play("success")
    }
}
