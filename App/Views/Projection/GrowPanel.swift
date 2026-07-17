import SwiftUI
import Charts
import BloomCore

struct GrowPanel: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(ProjectionStore.self) private var projectionStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(DraftStore.self) private var drafts

    @State private var yearlyBalances: [YearBalance] = []
    @State private var futureValueResult: Double = 0
    @State private var contributionsResult: Double = 0

    var body: some View {
        @Bindable var d = drafts
        Card {
            VStack(alignment: .leading, spacing: 16) {
                ProjectionFieldRow(
                    leftLabel: "Starting amount",
                    leftText: $d.grow.principal,
                    rightLabel: "Monthly added",
                    rightText: $d.grow.monthly
                )
                yearsSlider
                fundPicker
                ProjectionCalcButton(label: "Project the bloom", action: calculate)
                if drafts.grow.didCalculate {
                    resultSection
                }
                ProjectionDisclaimer(text: "Illustrative projection using a fixed annual rate, compounded monthly. Not financial advice, and no live trading.")
            }
        }
        // Order matters: a fresh budget handoff must land BEFORE the replay, or
        // her incoming number gets overwritten by a recompute of the old ones.
        .onAppear {
            consumePendingGrow()
            if drafts.grow.fundID == nil {
                drafts.grow.fundID = projectionStore.funds.first?.id
            }
            if drafts.grow.didCalculate { recompute() }
        }
        // A second handoff while the panel is already mounted (the outgoing
        // Budget view stays tappable during the slide transition, so a quick
        // double-tap bumps the epoch again) must consume immediately — a stale
        // pendingGrow would otherwise ambush a later plain visit.
        .onChange(of: projectionStore.jumpToGrowEpoch) { _, _ in
            consumePendingGrow()
        }
    }

    /// Budget handoff: a MONTHLY leftover fills the monthly field (principal is
    /// left alone) and pre-selects the fund nearest the S&P's ~10% long-run rate.
    /// %.0f instead of Int() — a silly 20-digit income must format, never trap.
    ///
    /// The result card is dropped: a new incoming number must never sit above an
    /// answer computed from the old one.
    private func consumePendingGrow() {
        guard let pending = projectionStore.pendingGrow else { return }
        drafts.grow.monthly = String(format: "%.0f", max(0, pending.monthly.rounded()))
        drafts.grow.fundID = projectionStore.funds.min(by: { abs($0.ratePct - 10) < abs($1.ratePct - 10) })?.id
        drafts.grow.didCalculate = false
        projectionStore.pendingGrow = nil
        ToastCenter.shared.show(title: "From your budget", message: "Your monthly leftover, growing at the market's long-run pace.")
    }

    private var yearsSlider: some View {
        @Bindable var d = drafts
        return VStack(alignment: .leading, spacing: 6) {
            Text("Years to grow: \(Int(drafts.grow.years))")
                .font(bloomBody(12, weight: .medium))
                .foregroundStyle(themeStore.color("muted"))
            Slider(value: $d.grow.years, in: 1...40, step: 1)
                .tint(themeStore.color("primaryStrong"))
        }
    }

    private var fundPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choose a fund profile")
                .font(bloomBody(12, weight: .medium))
                .foregroundStyle(themeStore.color("muted"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(projectionStore.funds) { fund in
                        fundChip(fund)
                    }
                }
            }
        }
    }

    private func fundChip(_ fund: Fund) -> some View {
        let isSelected = fund.id == drafts.grow.fundID
        return Button {
            drafts.grow.fundID = fund.id
        } label: {
            VStack(spacing: 2) {
                Text(fund.name)
                    .font(bloomBody(12, weight: .semibold))
                Text("\(Formatters.plain(fund.ratePct))%")
                    .font(bloomBody(10))
            }
            .foregroundStyle(isSelected ? .white : themeStore.color("text"))
            .padding(.horizontal, 14)
            .frame(minWidth: 44, minHeight: 44)
            .background(isSelected ? themeStore.color("primaryStrong") : themeStore.color("surfaceSoft"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
        }
        .buttonStyle(TactilePressStyle(cornerRadius: 12))
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                FlowerLogo(size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("PROJECTED VALUE")
                        .font(bloomBody(10, weight: .semibold))
                        .foregroundStyle(themeStore.color("muted"))
                    RollingNumberText(
                        text: Formatters.money(futureValueResult),
                        font: bloomNumber(28, weight: .semibold),
                        color: themeStore.color("deep")
                    )
                }
            }
            HStack(spacing: 20) {
                ProjectionResultStat(label: "You put in", value: Formatters.money(contributionsResult))
                ProjectionResultStat(label: "Growth", value: Formatters.money(futureValueResult - contributionsResult), isGrowth: true)
            }
            if !yearlyBalances.isEmpty {
                growthChart
            }
        }
    }

    private var growthChart: some View {
        Chart(yearlyBalances) { point in
            AreaMark(
                x: .value("Year", point.year),
                y: .value("Balance", point.balance)
            )
            .foregroundStyle(themeStore.color("primary").opacity(0.25))
            LineMark(
                x: .value("Year", point.year),
                y: .value("Balance", point.balance)
            )
            .foregroundStyle(themeStore.color("primaryStrong"))
        }
        .frame(height: 150)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .accessibilityLabel("Projected growth chart")
        .accessibilityValue("Grows to \(Formatters.money(futureValueResult)) over \(max(yearlyBalances.count - 1, 1)) years")
        .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: yearlyBalances.count)
    }

    /// The maths only. `calculate()` adds the things that must happen once per
    /// tap — a history row, a sound — and must never fire on a silent replay.
    private func recompute() {
        let principal = Double(drafts.grow.principal) ?? 0
        let monthly = Double(drafts.grow.monthly) ?? 0
        let years = drafts.grow.years
        let rate = currentRate

        futureValueResult = FinanceMath.futureValue(principal: principal, monthly: monthly, annualRatePct: rate, years: years)
        contributionsResult = FinanceMath.contributions(principal: principal, monthly: monthly, years: years)

        var points: [YearBalance] = []
        let totalYears = max(Int(years), 1)
        for year in 0...totalYears {
            let balance = FinanceMath.futureValue(principal: principal, monthly: monthly, annualRatePct: rate, years: Double(year))
            points.append(YearBalance(year: year, balance: balance))
        }
        yearlyBalances = points
    }

    private var currentRate: Double {
        projectionStore.funds.first { $0.id == drafts.grow.fundID }?.ratePct ?? 6
    }

    private func calculate() {
        recompute()
        drafts.grow.didCalculate = true

        historyStore.add(
            type: "proj",
            title: "Grow",
            value: Formatters.money(futureValueResult),
            extra: [
                "principal": drafts.grow.principal,
                "monthly": drafts.grow.monthly,
                "years": String(Int(drafts.grow.years)),
                "ratePct": Formatters.plain(currentRate)
            ]
        )
        soundStore.play("success")
    }
}

private struct YearBalance: Identifiable {
    let year: Int
    let balance: Double
    var id: Int { year }
}
